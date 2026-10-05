#include "TaskbarMonitor.h"
#include "AppSettings.h"
#include "CodexRateLimitModel.h"
#include <QImage>
#include <QDateTime>
#include <QPainter>
#include <QSettings>
#include <QThread>
#include <memory>
#include <algorithm>
#ifdef Q_OS_WIN
#include <windows.h>
#include <commctrl.h>
#include <uiautomation.h>

namespace {
QRect rectOf(HWND window) {
    RECT r{};
    if (!GetWindowRect(window, &r)) return {};
    return QRect(r.left, r.top, r.right-r.left, r.bottom-r.top);
}
QVector<QRect> occupiedControls(HWND shell) {
    QVector<QRect> result;
    IUIAutomation *automation = nullptr;
    if (FAILED(CoCreateInstance(CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER,
                                IID_IUIAutomation, reinterpret_cast<void **>(&automation)))) return result;
    IUIAutomationElement *root = nullptr;
    IUIAutomationCondition *condition = nullptr;
    IUIAutomationElementArray *elements = nullptr;
    if (SUCCEEDED(automation->ElementFromHandle(shell, &root))
            && SUCCEEDED(automation->CreateTrueCondition(&condition))
            && SUCCEEDED(root->FindAll(TreeScope_Descendants, condition, &elements))) {
        int count = 0;
        elements->get_Length(&count);
        for (int i=0; i<count; ++i) {
            IUIAutomationElement *element = nullptr;
            if (FAILED(elements->GetElement(i, &element))) continue;
            CONTROLTYPEID type = 0;
            BOOL offscreen = TRUE;
            RECT rect{};
            element->get_CurrentControlType(&type);
            element->get_CurrentIsOffscreen(&offscreen);
            if (!offscreen && (type == UIA_ButtonControlTypeId || type == UIA_ListItemControlTypeId
                              || type == UIA_EditControlTypeId || type == UIA_TextControlTypeId)
                    && SUCCEEDED(element->get_CurrentBoundingRectangle(&rect)))
                result.append(QRect(rect.left, rect.top, rect.right-rect.left, rect.bottom-rect.top));
            element->Release();
        }
    }
    if (elements) elements->Release();
    if (condition) condition->Release();
    if (root) root->Release();
    automation->Release();
    return result;
}
LRESULT CALLBACK surfaceProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
    auto *self = reinterpret_cast<TaskbarMonitor *>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        auto *creation = reinterpret_cast<CREATESTRUCTW *>(lparam);
        SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(creation->lpCreateParams));
    }
    if (self && message == WM_LBUTTONUP) { emit self->activated(); return 0; }
    if (message == WM_MOUSEACTIVATE) return MA_NOACTIVATE;
    if (message == WM_ERASEBKGND) return 1;
    return DefWindowProcW(window, message, wparam, lparam);
}
}
#endif

TaskbarMonitor::TaskbarMonitor(AppSettings *settings, CodexRateLimitModel *model, QObject *parent)
    : QObject(parent), m_settings(settings), m_model(model) {
    connect(settings, &AppSettings::taskbarMonitorChanged, this, &TaskbarMonitor::refresh);
    connect(model, &QAbstractItemModel::modelReset, this, &TaskbarMonitor::render);
    connect(model, &QAbstractItemModel::dataChanged, this, &TaskbarMonitor::render);
    connect(&m_timer, &QTimer::timeout, this, &TaskbarMonitor::refresh);
    refresh();
}
TaskbarMonitor::~TaskbarMonitor() {
    closeSurface();
}
QRect TaskbarMonitor::freeSlot(const QRect &bounds, const QVector<QRect> &occupied, const QSize &size) {
    if (size.width() > bounds.width() || size.height() > bounds.height()) return {};
    const bool horizontal = bounds.width() >= bounds.height();
    for (int end = horizontal ? bounds.right()+1 : bounds.bottom()+1;
         end >= (horizontal ? bounds.left()+size.width() : bounds.top()+size.height()); --end) {
        QRect slot = horizontal
            ? QRect(end-size.width(), bounds.y()+(bounds.height()-size.height())/2, size.width(), size.height())
            : QRect(bounds.x()+(bounds.width()-size.width())/2, end-size.height(), size.width(), size.height());
        if (std::none_of(occupied.cbegin(), occupied.cend(), [&](const QRect &r) { return slot.intersects(r.adjusted(-4,-2,4,2)); }))
            return slot;
    }
    return {};
}
QString TaskbarMonitor::summary() const {
    QStringList lines{tr("Codex — quota residua")};
    for (int i=0; i<m_model->rowCount(); ++i) {
        const auto entry = m_model->get(i);
        const QString label = entry.value("isReserve").toBool() ? tr("Reserve")
            : entry.value("displayBucket").toString();
        lines.append(QStringLiteral("%1: %2% · %3").arg(label)
                     .arg(entry.value("remainingPercent").toInt()).arg(entry.value("resetText").toString()));
    }
    if (!m_model->rowCount()) lines.append(tr("In attesa dei dati"));
    lines.append(tr("Clicca per aprire Codex Meter"));
    return lines.join('\n');
}
void TaskbarMonitor::closeSurface() {
#ifdef Q_OS_WIN
    auto tooltip = reinterpret_cast<HWND>(m_tooltip);
    if (tooltip && IsWindow(tooltip)) DestroyWindow(tooltip);
    m_tooltip = 0;
    auto window = reinterpret_cast<HWND>(m_window);
    if (window && IsWindow(window)) DestroyWindow(window);
#endif
    m_window = 0;
}
void TaskbarMonitor::refresh() {
    if (!m_settings->taskbarMonitor()) { m_timer.stop(); closeSurface(); return; }
    if (!m_timer.isActive()) m_timer.start(2000);
#ifdef Q_OS_WIN
    HWND shell = FindWindowW(L"Shell_TrayWnd", nullptr);
    if (!shell || !IsWindowVisible(shell)) { closeSurface(); return; }
    if (m_scanRunning) return;
    m_scanRunning = true;
    auto occupied = std::make_shared<QVector<QRect>>();
    auto *worker = QThread::create([shell, occupied] {
        const HRESULT initialized = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
        if (SUCCEEDED(initialized)) {
            *occupied = occupiedControls(shell);
            CoUninitialize();
        }
    });
    connect(worker, &QThread::finished, this, [this, shell, occupied] {
        m_scanRunning = false;
        if (m_settings->taskbarMonitor()) applyLayout(reinterpret_cast<quintptr>(shell), *occupied);
    });
    connect(worker, &QThread::finished, worker, &QObject::deleteLater);
    worker->start();
#endif
}
void TaskbarMonitor::applyLayout(quintptr shellHandle, const QVector<QRect> &controls) {
#ifdef Q_OS_WIN
    HWND shell = reinterpret_cast<HWND>(shellHandle);
    if (!IsWindow(shell) || shell != FindWindowW(L"Shell_TrayWnd", nullptr)
            || !IsWindowVisible(shell)) { closeSurface(); return; }
    const QRect bar = rectOf(shell);
    if (bar.width()<8 || bar.height()<8) { closeSurface(); return; }
    const UINT dpi = GetDpiForWindow(shell);
    const double scale = dpi / 96.0;
    m_size = bar.width() >= bar.height()
        ? QSize(qRound(230*scale), qMin(bar.height()-4, qRound(44*scale)))
        : QSize(bar.width()-4, qRound(64*scale));
    QVector<QRect> occupied = controls;
    // Keep clear of Start even when an accessibility provider is unavailable.
    if (occupied.isEmpty()) { closeSurface(); return; }
    if (HWND tray = FindWindowExW(shell, nullptr, L"TrayNotifyWnd", nullptr)) occupied.append(rectOf(tray));
    const QRect slot = freeSlot(bar.adjusted(4,2,-4,-2), occupied, m_size);
    if (slot.isEmpty()) { closeSurface(); return; }
    HWND window = reinterpret_cast<HWND>(m_window);
    if (!window || !IsWindow(window)) {
        closeSurface();
        WNDCLASSW wc{};
        wc.lpfnWndProc = surfaceProc; wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = L"CodexMeterTaskbar"; wc.hCursor = LoadCursorW(nullptr, IDC_HAND);
        RegisterClassW(&wc);
        const auto oldDpi = SetThreadDpiAwarenessContext(GetWindowDpiAwarenessContext(shell));
        window = CreateWindowExW(WS_EX_LAYERED|WS_EX_NOACTIVATE|WS_EX_TOOLWINDOW,
            wc.lpszClassName, L"Codex Meter — quota residua", WS_POPUP,
            0,0,m_size.width(),m_size.height(),nullptr,nullptr,wc.hInstance,this);
        SetThreadDpiAwarenessContext(oldDpi);
        m_window = reinterpret_cast<quintptr>(window);
        if (!window) return;
        INITCOMMONCONTROLSEX common{sizeof(INITCOMMONCONTROLSEX), ICC_WIN95_CLASSES};
        InitCommonControlsEx(&common);
        HWND tooltip = CreateWindowExW(WS_EX_TOPMOST | WS_EX_NOACTIVATE, TOOLTIPS_CLASSW, nullptr,
            WS_POPUP | TTS_ALWAYSTIP | TTS_NOPREFIX, CW_USEDEFAULT, CW_USEDEFAULT,
            CW_USEDEFAULT, CW_USEDEFAULT, window, nullptr, wc.hInstance, nullptr);
        m_tooltip = reinterpret_cast<quintptr>(tooltip);
        if (tooltip) {
            m_tooltipText = summary();
            TOOLINFOW tool{}; tool.cbSize = sizeof(tool);
            tool.uFlags = TTF_IDISHWND | TTF_SUBCLASS; tool.hwnd = window;
            tool.uId = reinterpret_cast<UINT_PTR>(window);
            tool.lpszText = reinterpret_cast<LPWSTR>(m_tooltipText.data());
            SendMessageW(tooltip, TTM_ADDTOOLW, 0, reinterpret_cast<LPARAM>(&tool));
            SendMessageW(tooltip, TTM_SETMAXTIPWIDTH, 0, 380);
            SendMessageW(tooltip, TTM_SETDELAYTIME, TTDT_INITIAL, 350);
            SendMessageW(tooltip, TTM_SETDELAYTIME, TTDT_AUTOPOP, 32767);
        }
    }
    SetWindowPos(window, HWND_TOPMOST, slot.x(),slot.y(),m_size.width(),m_size.height(),SWP_NOACTIVATE|SWP_SHOWWINDOW);
    SetWindowRgn(window,CreateRoundRectRgn(0,0,m_size.width()+1,m_size.height()+1,8,8),TRUE);
    render();
#endif
}
void TaskbarMonitor::render() {
#ifdef Q_OS_WIN
    HWND window = reinterpret_cast<HWND>(m_window);
    if (!window || !IsWindow(window)) return;
    QImage image(m_size, QImage::Format_ARGB32_Premultiplied);
    // Alpha 1 keeps the whole surface hoverable without a visible background.
    image.fill(QColor(0, 0, 0, 1));
    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing);
    QSettings theme(QStringLiteral("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"), QSettings::NativeFormat);
    const bool light = theme.value("SystemUsesLightTheme",0).toBool();
    const double scale = GetDpiForWindow(window)/96.0;
    QFont font("Poppins"); font.setPixelSize(qMax(9,qRound(11*scale))); painter.setFont(font);
    const int rows = qMin(2,m_model->rowCount());
    if (!rows) {
        painter.setPen(light ? QColor("#333333") : QColor("#dddddd"));
        painter.drawText(image.rect(),Qt::AlignCenter,tr("Codex\nIn attesa…"));
    }
    for (int i=0;i<rows;++i) {
        const auto entry = m_model->get(i);
        const int percent = qBound(0,entry.value("remainingPercent").toInt(),100);
        const QColor accent = percent < 10 ? QColor("#D9534F")
            : percent < 35 ? QColor("#F0A020") : QColor("#0091FF");
        const int padding = qRound(8*scale);
        const QRect row(padding,i*image.height()/2,image.width()-2*padding,image.height()/2);
        const auto minutes = entry.value("windowMinutes").toLongLong();
        const QString label = entry.value("bucket").toString() == "Week" ? tr("7g")
            : minutes > 0 && minutes % 60 == 0 ? tr("%1 h").arg(minutes / 60)
            : entry.value("displayBucket").toString();
        painter.setPen(light ? QColor("#252a32") : QColor("#eef1f5"));
        painter.drawText(row,Qt::AlignLeft|Qt::AlignVCenter,label);
        const QRectF track(row.left()+28*scale,row.center().y()-3*scale,64*scale,6*scale);
        painter.setPen(Qt::NoPen);
        painter.setBrush(light ? QColor("#D9DCDF") : QColor("#454A52"));
        painter.drawRoundedRect(track,3*scale,3*scale);
        painter.setBrush(accent);
        if (percent) painter.drawRoundedRect(QRectF(track.x(),track.y(),track.width()*percent/100.0,track.height()),3*scale,3*scale);
        painter.setPen(QColor("#FFFFFF"));
        painter.drawText(QRect(row.left()+qRound(98*scale),row.top(),qRound(36*scale),row.height()),Qt::AlignRight|Qt::AlignVCenter,QString::number(percent)+"%");
        const qint64 reset = entry.value("resetTimestamp").toLongLong();
        const qint64 seconds = qMax(qint64(0), reset-QDateTime::currentSecsSinceEpoch());
        QString countdown = QStringLiteral("--");
        if (reset > 0) countdown = seconds >= 86400
            ? tr("%1g %2h").arg(seconds/86400).arg((seconds%86400)/3600)
            : tr("%1h %2m").arg(seconds/3600).arg((seconds%3600)/60);
        painter.setPen(light ? QColor("#777D85") : QColor("#B9BDC3"));
        painter.drawText(QRect(row.left()+qRound(142*scale),row.top(),row.width()-qRound(142*scale),row.height()),Qt::AlignRight|Qt::AlignVCenter,countdown);
    }
    painter.end();
    const QString tooltipText = summary();
    if (m_tooltip && tooltipText != m_tooltipText) {
        m_tooltipText = tooltipText;
        TOOLINFOW tool{}; tool.cbSize = sizeof(tool); tool.hwnd = window;
        tool.uId = reinterpret_cast<UINT_PTR>(window);
        tool.lpszText = reinterpret_cast<LPWSTR>(m_tooltipText.data());
        SendMessageW(reinterpret_cast<HWND>(m_tooltip), TTM_UPDATETIPTEXTW, 0, reinterpret_cast<LPARAM>(&tool));
    }
    HDC screen=GetDC(nullptr), memory=CreateCompatibleDC(screen);
    BITMAPINFO info{}; info.bmiHeader.biSize=sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth=image.width(); info.bmiHeader.biHeight=-image.height();
    info.bmiHeader.biPlanes=1; info.bmiHeader.biBitCount=32; info.bmiHeader.biCompression=BI_RGB;
    void *bits=nullptr;
    HBITMAP bitmap=CreateDIBSection(screen,&info,DIB_RGB_COLORS,&bits,nullptr,0);
    if (bitmap && bits) {
        memcpy(bits,image.constBits(),image.sizeInBytes());
        HGDIOBJ previous=SelectObject(memory,bitmap);
        POINT source{}; SIZE size{image.width(),image.height()};
        BLENDFUNCTION blend{AC_SRC_OVER,0,255,AC_SRC_ALPHA};
        UpdateLayeredWindow(window,screen,nullptr,&size,memory,&source,0,&blend,ULW_ALPHA);
        SelectObject(memory,previous); DeleteObject(bitmap);
    }
    DeleteDC(memory); ReleaseDC(nullptr,screen);
#endif
}
