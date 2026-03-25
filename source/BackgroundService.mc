// BackgroundService.mc — фоновое расписание напоминаний (Free)
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
        _checkAndNotify();
        _scheduleNext();
    }

    // -------------------------------------------------------------------------
    // Проверка и отправка напоминания

    private function _checkAndNotify() as Void {
        if (!_isInTimeWindow()) { return; }

        var amount = DataStore.getAmount();
        var goal   = DataStore.getGoal();
        var rec    = DataStore.getRecommendedGoalBg();

        // Выпито >= REC — не беспокоить
        if (amount >= rec) { return; }

        _notify(1, "Stay hydrated");
    }

    // 1 = одна вибрация/тон
    private function _notify(count as Number, message as String) as Void {
        // Текстовое уведомление — всегда
        if ((Toybox has :Attention) && (Attention has :showWeakNotification)) {
            Attention.showWeakNotification("Water Tracker", message, {});
        }
        // Вибрация
        if (DataStore.getVibrate() && (Toybox has :Attention) && (Attention has :vibrate)) {
            if (count == 2) {
                Attention.vibrate([
                    new Attention.VibeProfile(75, 250),
                    new Attention.VibeProfile(0,  150),
                    new Attention.VibeProfile(75, 250)
                ]);
            } else {
                Attention.vibrate([new Attention.VibeProfile(75, 400)]);
            }
        }
        // Звук
        if (DataStore.getTone() && (Toybox has :Attention) && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
    }

    // Проверка временного окна From/To
    private function _isInTimeWindow() as Boolean {
        var now  = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var from = DataStore.getFromHour();
        var to   = DataStore.getToHour();
        return (now.hour >= from && now.hour < to);
    }

    // -------------------------------------------------------------------------
    // Перепланирование следующего события

    private function _scheduleNext() as Void {
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) {
                Background.deleteTemporalEvent();
            }
            return;
        }
        var next = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(next);
    }
}
