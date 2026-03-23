// SettingsView.mc — главное меню настроек и подменю напоминаний
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsData {
    static const GOALS          as Array<Number> =
        [1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 7000, 8000, 9000, 10000];
    static const INTERVALS      as Array<Number> = [0, 30, 60, 90, 120];
    static const FROM_HOURS     as Array<Number> = [6, 7, 8, 9, 10, 11, 12];
    static const TO_HOURS       as Array<Number> = [16, 17, 18, 19, 20, 21, 22, 23];
}

// =============================================================================
// Главное меню Settings: Reminders / Units / Formula

function pushSettingsMenu() as Void {
    var menu = new WatchUi.Menu2({:title => "Settings"});
    var remindersOn = DataStore.getSmart() || (DataStore.getInterval() > 0);
    var notifOn     = DataStore.getVibrate() || DataStore.getTone();
    var remItem  = new WatchUi.MenuItem("Reminders",    remindersOn ? "ON" : "OFF", :reminders,    {});
    var notifItem = new WatchUi.MenuItem("Notification", notifOn ? "ON" : "OFF",    :notification, {});
    menu.addItem(remItem);
    menu.addItem(notifItem);
    menu.addItem(new WatchUi.MenuItem("Units", (DataStore.getUnits() == 0) ? "ml" : "oz", :units, {}));
    menu.addItem(new WatchUi.MenuItem("Formula", null, :formula, {}));
    WatchUi.pushView(menu, new MainSettingsDelegate(remItem, notifItem), WatchUi.SLIDE_DOWN);
}

class MainSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _remItem   as WatchUi.MenuItem;
    private var _notifItem as WatchUi.MenuItem;

    function initialize(remItem as WatchUi.MenuItem, notifItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _remItem   = remItem;
        _notifItem = notifItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :reminders) {
            pushRemindersMenu(_remItem, _notifItem);
        } else if (id == :notification) {
            pushNotificationMenu(_notifItem);
        } else if (id == :units) {
            var newUnits = (DataStore.getUnits() == 0) ? 1 : 0;
            DataStore.setUnits(newUnits);
            item.setSubLabel((newUnits == 0) ? "ml" : "oz");
        } else if (id == :formula) {
            pushDebugProfileView();
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// =============================================================================
// Подменю Reminders: Smart / Interval / From / To

function pushRemindersMenu(parentRemItem as WatchUi.MenuItem, parentNotifItem as WatchUi.MenuItem) as Void {
    var smart    = DataStore.getSmart();
    var interval = DataStore.getInterval();
    var from     = DataStore.getFromHour();
    var to       = DataStore.getToHour();

    var menu = new WatchUi.Menu2({:title => "Reminders"});

    menu.addItem(new WatchUi.ToggleMenuItem("Smart",    null, :smart,    smart, {}));
    if (!smart) {
        menu.addItem(new WatchUi.MenuItem("Interval", _fmtInterval(interval), :interval, {}));
    }
    menu.addItem(new WatchUi.MenuItem("From", _fmtHour(from), :from, {}));
    menu.addItem(new WatchUi.MenuItem("To",   _fmtHour(to),   :to,   {}));

    WatchUi.pushView(menu, new RemindersDelegate(parentRemItem, parentNotifItem), WatchUi.SLIDE_UP);
}

class RemindersDelegate extends WatchUi.Menu2InputDelegate {
    private var _parentRemItem   as WatchUi.MenuItem;
    private var _parentNotifItem as WatchUi.MenuItem;

    function initialize(parentRemItem as WatchUi.MenuItem, parentNotifItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentRemItem   = parentRemItem;
        _parentNotifItem = parentNotifItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if      (id == :smart)    { _toggleSmart(item); }
        else if (id == :interval) { _cycleInterval(item); }
        else if (id == :from)     { _cycleFrom(item); }
        else if (id == :to)       { _cycleTo(item); }
    }

    function onBack() as Void {
        var remOn = DataStore.getSmart() || (DataStore.getInterval() > 0);
        var label = remOn ? "ON" : "OFF";
        _parentRemItem.setSubLabel(label);
        _parentNotifItem.setSubLabel(label);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    private function _toggleSmart(item as WatchUi.MenuItem) as Void {
        var smart = (item as WatchUi.ToggleMenuItem).isEnabled();
        DataStore.setSmart(smart);
        if (smart) {
            DataStore.setInterval(0);
            WaterTrackerApp.scheduleReminder();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        pushRemindersMenu(_parentRemItem, _parentNotifItem);
    }

    private function _cycleInterval(item as WatchUi.MenuItem) as Void {
        var values = SettingsData.INTERVALS; // [0, 30, 60, 90, 120]
        var idx    = _findIdx(values, DataStore.getInterval());
        idx = (idx + 1) % values.size();
        DataStore.setInterval(values[idx]);
        WaterTrackerApp.scheduleReminder();
        item.setSubLabel(_fmtInterval(values[idx]));
    }

    private function _cycleFrom(item as WatchUi.MenuItem) as Void {
        var hours = SettingsData.FROM_HOURS;
        var idx   = _findIdx(hours, DataStore.getFromHour());
        idx = (idx + 1) % hours.size();
        DataStore.setFromHour(hours[idx]);
        item.setSubLabel(_fmtHour(hours[idx]));
    }

    private function _cycleTo(item as WatchUi.MenuItem) as Void {
        var hours = SettingsData.TO_HOURS;
        var idx   = _findIdx(hours, DataStore.getToHour());
        idx = (idx + 1) % hours.size();
        DataStore.setToHour(hours[idx]);
        item.setSubLabel(_fmtHour(hours[idx]));
    }

    private function _findIdx(arr as Array<Number>, value as Number) as Number {
        for (var i = 0; i < arr.size(); i++) {
            if (arr[i] == value) { return i; }
        }
        return 0;
    }
}

// =============================================================================
// Подменю Notification: Vibrate / Tone

function pushNotificationMenu(parentNotifItem as WatchUi.MenuItem) as Void {
    var menu = new WatchUi.Menu2({:title => "Notification"});
    menu.addItem(new WatchUi.ToggleMenuItem("Vibrate", null, :vibrate, DataStore.getVibrate(), {}));
    menu.addItem(new WatchUi.ToggleMenuItem("Tone",    null, :tone,    DataStore.getTone(),    {}));
    WatchUi.pushView(menu, new NotificationDelegate(parentNotifItem), WatchUi.SLIDE_UP);
}

class NotificationDelegate extends WatchUi.Menu2InputDelegate {
    private var _parentNotifItem as WatchUi.MenuItem;

    function initialize(parentNotifItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentNotifItem = parentNotifItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :vibrate) {
            DataStore.setVibrate((item as WatchUi.ToggleMenuItem).isEnabled());
        } else if (id == :tone) {
            DataStore.setTone((item as WatchUi.ToggleMenuItem).isEnabled());
        }
    }

    function onBack() as Void {
        var notifOn = DataStore.getVibrate() || DataStore.getTone();
        _parentNotifItem.setSubLabel(notifOn ? "ON" : "OFF");
        WatchUi.popView(WatchUi.SLIDE_DOWN);
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

function _fmtHour(hour as Number) as String {
    return hour.toString() + ":00";
}
