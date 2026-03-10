// BackgroundService.mc — фоновые напоминания о воде
import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Фоновый сервис (выполняется независимо от UI)
(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    // Вызывается по расписанию temporalEvent
    function onTemporalEvent() as Void {
        // Не беспокоить если цель уже достигнута
        if (DataStore.isGoalReached()) {
            _scheduleNext(); // перенести следующий тик
            return;
        }

        // Не беспокоить в тихие часы (22:00 — 07:00)
        if (_isQuietHours()) {
            _scheduleNext();
            return;
        }

        // Вибрировать
        _vibrate();

        _scheduleNext();
    }

    // Зарегистрировать следующее событие
    private function _scheduleNext() as Void {
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            Background.deleteTemporalEvent();
            return;
        }
        var intervalSec = new Time.Duration(intervalMin * 60);
        Background.registerForTemporalEvent(Time.now().add(intervalSec));
    }

    // Тихие часы: 22:00 — 07:00
    private function _isQuietHours() as Boolean {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hour = info.hour;
        return (hour >= 22 || hour < 7);
    }

    // Паттерн вибрации — одиночный сигнал
    private function _vibrate() as Void {
        if (Attention has :vibrate) {
            var pattern = [
                new Attention.VibeProfile(100, 500), // 100% мощность, 500мс
                new Attention.VibeProfile(0,   200), // пауза 200мс
                new Attention.VibeProfile(100, 300)  // ещё один импульс
            ] as Array<Attention.VibeProfile>;
            Attention.vibrate(pattern);
        }
    }
}

// Вызывается из WaterTrackerApp при первом запуске для регистрации напоминаний
function registerBackgroundReminder() as Void {
    var intervalMin = DataStore.getInterval();
    if (intervalMin <= 0) { return; }

    var intervalSec = new Time.Duration(intervalMin * 60);
    Background.registerForTemporalEvent(Time.now().add(intervalSec));
}
