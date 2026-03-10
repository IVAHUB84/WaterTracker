// WaterTrackerApp.mc — точка входа приложения
import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class WaterTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Вызывается при запуске виджета
    function onStart(state as Dictionary?) as Void {
        _scheduleReminder();
    }

    // Вызывается при закрытии виджета
    function onStop(state as Dictionary?) as Void {
    }

    // Начальный экран
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new WaterTrackerView();
        var delegate = new WaterTrackerDelegate();
        return [view, delegate];
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
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            // Напоминания отключены — удалить существующее расписание
            Background.deleteTemporalEvent();
            return;
        }
        var nextEvent = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(nextEvent);
    }
}

// -----------------------------------------------------------------------------
// Делегат кнопок главного экрана

class WaterTrackerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // SELECT — добавить воду
    function onSelect() as Boolean {
        var view = new AddWaterView();
        WatchUi.pushView(view, new AddWaterDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }

    // UP — настройки
    function onPreviousPage() as Boolean {
        var settingsView = new SettingsView();
        WatchUi.pushView(settingsView, new SettingsDelegate(settingsView), WatchUi.SLIDE_DOWN);
        return true;
    }

    // BACK — выход
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
