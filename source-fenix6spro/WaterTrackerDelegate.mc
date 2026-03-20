// WaterTrackerDelegate.mc — делегат главного экрана (Instinct 3 AMOLED)
import Toybox.Lang;
import Toybox.WatchUi;

class WaterTrackerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WaterTrackerView;

    function initialize(view as WaterTrackerView) {
        BehaviorDelegate.initialize();
        _view = view;
        _view.setShowSelection(true);
        _view.setBoldWhite(true);
        _view.addFormulaItem();
    }

    // MENU (долгое нажатие UP) → Formula
    function onMenu() as Boolean {
        pushDebugProfileView();
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
        if      (itemIdx == 0) { DataStore.addAmount(-100); updateComplications(); }
        else if (itemIdx == 1) { DataStore.addAmount(100);  updateComplications(); }
        else if (itemIdx == 2) { DataStore.addAmount(250);  updateComplications(); }
        else if (itemIdx == 3) { DataStore.addAmount(500);  updateComplications(); }
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
