// SettingsView.mc — нативный Menu2 без заголовка (плавная прокрутка)
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsData {
    static const GOALS as Array<Number> =
        [1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 7000, 8000, 9000, 10000];
    static const INTERVALS as Array<Number> = [0, 30, 60, 90, 120];
}

// =============================================================================
// Открыть меню настроек

function pushSettingsMenu() as Void {
    var menu = new WatchUi.Menu2({});   // без заголовка

    var units   = DataStore.getUnits();
    var goalMl  = DataStore.getGoal();
    var intrMin = DataStore.getInterval();

    menu.addItem(new WatchUi.MenuItem(
        "Daily Goal", _fmtGoal(goalMl, units), :goal, {}));
    menu.addItem(new WatchUi.MenuItem(
        "Reminder", _fmtInterval(intrMin), :interval, {}));
    menu.addItem(new WatchUi.MenuItem(
        "Units", (units == 0) ? "ml" : "oz", :units, {}));

    WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_DOWN);
}

// =============================================================================
// Делегат меню настроек

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if      (id == :goal)     { _cycleGoal(item); }
        else if (id == :interval) { _cycleInterval(item); }
        else if (id == :units)    { _cycleUnits(item); }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function _cycleGoal(item as WatchUi.MenuItem) as Void {
        var goals = SettingsData.GOALS;
        var idx   = _findIdx(goals, DataStore.getGoal());
        idx = (idx + 1) % goals.size();
        DataStore.setGoal(goals[idx], true);
        item.setSubLabel(_fmtGoal(goals[idx], DataStore.getUnits()));
    }

    private function _cycleInterval(item as WatchUi.MenuItem) as Void {
        var intvs = SettingsData.INTERVALS;
        var idx   = _findIdx(intvs, DataStore.getInterval());
        idx = (idx + 1) % intvs.size();
        DataStore.setInterval(intvs[idx]);
        WaterTrackerApp.scheduleReminder();
        item.setSubLabel(_fmtInterval(intvs[idx]));
    }

    private function _cycleUnits(item as WatchUi.MenuItem) as Void {
        var newUnits = (DataStore.getUnits() == 0) ? 1 : 0;
        DataStore.setUnits(newUnits);
        item.setSubLabel((newUnits == 0) ? "ml" : "oz");
    }

    private function _findIdx(arr as Array<Number>, value as Number) as Number {
        for (var i = 0; i < arr.size(); i++) {
            if (arr[i] == value) { return i; }
        }
        return 0;
    }
}

// =============================================================================
// Форматтеры

function _fmtGoal(ml as Number, units as Number) as String {
    if (units == 0) { return ml.toString() + " ml"; }
    return (ml.toFloat() / 29.5735f).format("%.0f") + " oz";
}

function _fmtInterval(min as Number) as String {
    if (min == 0) { return "Off"; }
    return min.toString() + " min";
}
