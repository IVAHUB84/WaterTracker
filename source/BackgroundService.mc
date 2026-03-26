// BackgroundService.mc — фоновое расписание напоминаний (Free)
import Toybox.Application;
import Toybox.Attention;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var t = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var ts = t.hour.toString() + ":" +
                 (t.min < 10 ? "0" : "") + t.min.toString();
        Application.Storage.setValue("_bgFired", ts);
        Application.Storage.setValue("_bgDbg", ts + " start");

        _checkAndNotify();
        _scheduleNext();
    }

    // -------------------------------------------------------------------------
    // Проверка и отправка напоминания

    private function _checkAndNotify() as Void {
        var t  = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var ts = t.hour.toString() + ":" + (t.min < 10 ? "0" : "") + t.min.toString();

        Application.Storage.setValue("_bgDbg", ts + " A");
        if (!_isInTimeWindow()) {
            Application.Storage.setValue("_bgDbg", ts + " nowin");
            return;
        }

        Application.Storage.setValue("_bgDbg", ts + " B");
        var amount = DataStore.getAmount();

        Application.Storage.setValue("_bgDbg", ts + " C");
        var rec = DataStore.getRecommendedGoalBg();

        Application.Storage.setValue("_bgDbg", ts + " D");
        if (amount >= rec) {
            Application.Storage.setValue("_bgDbg", ts + " done");
            return;
        }

        _notify("Stay hydrated");
        Application.Storage.setValue("_bgDbg", ts + " sent");
    }

    private function _notify(message as String) as Void {
        if (Attention has :showWeakNotification) {
            Attention.showWeakNotification("Water Tracker", message, null);
        }
    }

    // Проверка временного окна From/To
    private function _isInTimeWindow() as Boolean {
        var now  = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var from = DataStore.getFromHour();
        var to   = DataStore.getToHour();
        // to = 0 означает полночь (00:00) = конец дня, hour < 24 всегда true
        var toEffective = (to == 0) ? 24 : to;
        return (now.hour >= from && now.hour < toEffective);
    }

    // -------------------------------------------------------------------------
    // Перепланирование следующего события

    private function _scheduleNext() as Void {
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) {
                Background.deleteTemporalEvent();
            }
            Application.Storage.deleteValue("_nextReminderAt");
            return;
        }
        var next = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(next);
        var v = next.value();
        Application.Storage.setValue("_nextReminderAt",
            (v instanceof Long) ? (v as Long).toNumber() : (v as Number));
    }
}
