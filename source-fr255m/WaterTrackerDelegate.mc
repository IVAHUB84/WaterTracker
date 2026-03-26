// WaterTrackerDelegate.mc — делегат главного экрана (кнопочные устройства Fenix 6)
import Toybox.Lang;
import Toybox.WatchUi;

class WaterTrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WaterTrackerView;

    function initialize(view as WaterTrackerView) {
        BehaviorDelegate.initialize();
        _view = view;
        _view.setShowSelection(true);
        _view.addFormulaItem();  // добавляет 7-й пункт "GOAL+/-"
    }

    // MENU (долгое нажатие UP) → Settings
    function onMenu() as Boolean {
        pushSettingsMenu();
        return true;
    }

    // UP — прокрутка вверх
    function onPreviousPage() as Boolean {
        _view.scrollUp();
        return true;
    }

    // DOWN — прокрутка вниз
    function onNextPage() as Boolean {
        _view.scrollDown();
        return true;
    }

    // SELECT — выполнить действие верхнего пункта
    function onSelect() as Boolean {
        var itemIdx = _view.getScrollTop() % 7;
        _view.flashZone(ZONE_SLOT0);
        var isOz = (DataStore.getUnits() == 1);
        if      (itemIdx == 0) { DataStore.addAmount(isOz ? -237 : -100); updateComplications(); }
        else if (itemIdx == 1) { DataStore.addAmount(isOz ?  237 :  100); updateComplications(); }
        else if (itemIdx == 2) { DataStore.addAmount(isOz ?  473 :  250); updateComplications(); }
        else if (itemIdx == 3) { DataStore.addAmount(isOz ?  591 :  500); updateComplications(); }
        else if (itemIdx == 4) { pushQuickAddView(); }
        else if (itemIdx == 5) { pushResetConfirm(); }
        else if (itemIdx == 6) { pushGoalPickerView(); }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
