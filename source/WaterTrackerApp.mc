// WaterTrackerApp.mc — точка входа приложения
import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class WaterTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Вызывается при запуске виджета
    // При первом запуске авто-устанавливаем цель из профиля пользователя
    function onStart(state as Dictionary?) as Void {
        var initialized = Application.Storage.getValue("goalInitialized");
        if (!(initialized instanceof Boolean) || !(initialized as Boolean)) {
            var rec = DataStore.getRecommendedGoal();
            DataStore.setGoal(rec);
            Application.Storage.setValue("goalInitialized", true);
        }
    }

    // Вызывается при закрытии виджета
    function onStop(state as Dictionary?) as Void {
    }

    // Начальный экран
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new WaterTrackerView();
        return [view, new WaterTrackerDelegate(view)];
    }

    // Точка входа фонового сервиса — аннотация обязательна
    (:background)
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

    // Фоновый сервис не передаёт данные обратно
    function onBackgroundData(data as Application.PersistableType) as Void {
    }

    // -------------------------------------------------------------------------
    // Управление расписанием напоминаний

    // Зарегистрировать следующее напоминание согласно настройке интервала
    static function scheduleReminder() as Void {
        _scheduleReminder();
    }

    private static function _scheduleReminder() as Void {
        if (!(Background has :registerForTemporalEvent)) {
            return;
        }
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) {
                Background.deleteTemporalEvent();
            }
            return;
        }
        var nextEvent = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(nextEvent);
    }
}

// -----------------------------------------------------------------------------
// Делегат кнопок главного экрана

class WaterTrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view       as WaterTrackerView;
    private var _lastDragY  as Number = -1;

    function initialize(view as WaterTrackerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Долгое нажатие на левую половину (GOAL) → установка цели
    function onHold(evt as WatchUi.ClickEvent) as Boolean {
        if (evt.getCoordinates()[0] < _view.getBtnX()) {
            pushGoalPickerView();
        }
        return true;
    }

    // MENU (долгое нажатие UP) — debug-экран профиля пользователя
    function onMenu() as Boolean {
        pushDebugProfileView();
        return true;
    }

    // Физ. кнопки UP/DOWN — прокрутка
    function onPreviousPage() as Boolean {
        _view.scrollUp();
        return true;
    }

    function onNextPage() as Boolean {
        _view.scrollDown();
        return true;
    }

    // Drag пальцем — надёжная прокрутка правого столбца
    function onDrag(evt as WatchUi.DragEvent) as Boolean {
        var y = evt.getCoordinates()[1];
        if (_lastDragY < 0) {
            _lastDragY = y;
            return true;
        }
        var diff = _lastDragY - y;
        // Большой скачок = начало нового жеста, просто запомнить
        if (diff > 70 || diff < -70) {
            _lastDragY = y;
            return true;
        }
        if (diff > 30) {
            _view.scrollDown();
            _lastDragY = y;
        } else if (diff < -30) {
            _view.scrollUp();
            _lastDragY = y;
        }
        return true;
    }

    // TAP — определяем зону, подсвечиваем, выполняем действие
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _lastDragY = -1;
        var coords = evt.getCoordinates();
        var zone   = _view.getZoneForTap(coords[0], coords[1]);
        if (zone == ZONE_NONE) { return true; }

        if (zone == ZONE_SCROLL_UP)   { _view.scrollUp();                    return true; }
        if (zone == ZONE_SCROLL_DOWN) { _view.scrollDown();                   return true; }
        if (zone == ZONE_WARNING)     { pushProfileWarningView();             return true; }


        var itemIdx = (_view.getScrollTop() + zone) % RIGHT_ITEM_COUNT;
        _view.flashZone(zone);

        if      (itemIdx == 0) { DataStore.addAmount(-100); }
        else if (itemIdx == 1) { DataStore.addAmount(100); }
        else if (itemIdx == 2) { DataStore.addAmount(250); }
        else if (itemIdx == 3) { DataStore.addAmount(500); }
        else if (itemIdx == 4) { pushQuickAddView(); }
        else if (itemIdx == 5) { pushResetConfirm(); }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// -----------------------------------------------------------------------------
// Глобальный доступ к экземпляру приложения

function getApp() as WaterTrackerApp {
    return Application.getApp() as WaterTrackerApp;
}

