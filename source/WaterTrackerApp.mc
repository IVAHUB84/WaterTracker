// WaterTrackerApp.mc — точка входа приложения
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WaterTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Возвращает начальный View
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new WaterTrackerView();
        var delegate = new WaterTrackerDelegate(view);
        return [view, delegate];
    }

    // Точка входа фонового сервиса
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

    // Вызывается при возврате из фонового режима
    function onBackgroundData(data as Application.PersistableType) as Void {
        // Фоновый сервис не передаёт данные, только вибрирует
    }
}

// Делегат кнопок главного экрана
class WaterTrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WaterTrackerView;

    function initialize(view as WaterTrackerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // SELECT — переход на экран добавления воды
    function onSelect() as Boolean {
        WatchUi.pushView(
            new AddWaterView(),
            new AddWaterDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    // UP — переход в настройки
    function onPreviousPage() as Boolean {
        WatchUi.pushView(
            new SettingsView(),
            new SettingsDelegate(),
            WatchUi.SLIDE_DOWN
        );
        return true;
    }

    // BACK — выход из виджета
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// Регистрация приложения
function getApp() as WaterTrackerApp {
    return Application.getApp() as WaterTrackerApp;
}
