// BackgroundService.mc — фоновое расписание и умные напоминания
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
        var rec    = DataStore.getRecommendedGoal();

        // Выпито >= REC — не беспокоить
        if (amount >= rec) { return; }

        if (DataStore.getSmart()) {
            _smartNotify(amount, goal, rec);
        } else {
            _notify(1, "Time to drink water!");
        }
    }

    // Умное напоминание
    private function _smartNotify(amount as Number, goal as Number, rec as Number) as Void {
        var now         = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var fromHour    = DataStore.getFromHour();
        var toHour      = DataStore.getToHour();
        var totalMins   = (toHour - fromHour) * 60;
        var elapsedMins = (now.hour - fromHour) * 60 + now.min;
        if (elapsedMins < 0) { elapsedMins = 0; }

        var idealProgress  = (totalMins > 0) ? (elapsedMins.toFloat() / totalMins) : 0.0f;
        var actualProgress = (goal > 0) ? (amount.toFloat() / goal) : 0.0f;

        var lastTime = DataStore.getLastTime();
        var minsSinceLast = 9999;
        if (lastTime != null) {
            minsSinceLast = (Time.now().value() - (lastTime as Number)) / 60;
        }

        // Достиг GOAL но не REC — была активность, нужно пить ещё
        if (amount >= goal) {
            _notify(2, "Active day! Drink more");
            return;
        }

        // Давно не пил (>90 мин)
        if (minsSinceLast > 90) {
            _notify(1, "Haven't drunk in 90+ min");
            return;
        }

        // Сильно отстаёт от темпа (>20%)
        if (actualProgress < idealProgress - 0.2f) {
            _notify(1, "Drink water! You're behind schedule");
            return;
        }

        // Отстаёт немного (>10%)
        if (actualProgress < idealProgress - 0.1f) {
            _notify(1, "Time to drink water!");
        }
    }

    // 1 = одна вибрация/тон, 2 = двойная (активность)
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
        var intervalMin = DataStore.getSmart() ? 30 : DataStore.getInterval();
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
