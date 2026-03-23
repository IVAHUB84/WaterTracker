// WaterTrackerDelegate.mc — делегат главного экрана (touch-устройства)
import Toybox.Lang;
import Toybox.WatchUi;

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

        if (zone == ZONE_SCROLL_UP)   { _view.scrollUp();          return true; }
        if (zone == ZONE_SCROLL_DOWN) { _view.scrollDown();         return true; }
        if (zone == ZONE_WARNING)     { pushProfileWarningView();   return true; }
        if (zone == ZONE_REC)         { return true; }

        var itemIdx = (_view.getScrollTop() + zone) % RIGHT_ITEM_COUNT;
        _view.flashZone(zone);

        if      (itemIdx == 0) { DataStore.addAmount(-100); updateComplications(); }
        else if (itemIdx == 1) { DataStore.addAmount(100);  updateComplications(); }
        else if (itemIdx == 2) { DataStore.addAmount(250);  updateComplications(); }
        else if (itemIdx == 3) { DataStore.addAmount(500);  updateComplications(); }
        else if (itemIdx == 4) { pushQuickAddView(); }
        else if (itemIdx == 5) { pushResetConfirm(); }
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
