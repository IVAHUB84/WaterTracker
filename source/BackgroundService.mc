// BackgroundService.mc — фоновые напоминания о воде
import Toybox.Attention;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Фоновый сервис: выполняется в отдельном фоновом процессе
// Аннотация (:background) обязательна — включает класс в background-сборку
(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    // Вызывается по расписанию temporal event
    function onTemporalEvent() as Void {
        // 1. Проверить: цель выполнена — не беспокоить
        if (DataStore.isGoalReached()) {
            _scheduleNext();
            return;
        }

        // 2. Проверить: тихие часы (22:00 — 07:00) — не беспокоить
        if (_isQuietHours()) {
            _scheduleNext();
            return;
        }

        // 3. Вибрировать и запланировать следующее напоминание
        _vibrate();
        _scheduleNext();
    }

    // -------------------------------------------------------------------------
    // Приватные методы

    // Запланировать следующее событие по текущему интервалу
    private function _scheduleNext() as Void {
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            Background.deleteTemporalEvent();
            return;
        }
        var next = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(next);
    }

    // Тихие часы: 22:00 — 07:00
    private function _isQuietHours() as Boolean {
        var hour = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT).hour as Number;
        return (hour >= 22 || hour < 7);
    }

    // Вибрация: два коротких импульса (напоминание о воде)
    private function _vibrate() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0,   150),
                new Attention.VibeProfile(100, 250)
            ] as Array<Attention.VibeProfile>);
        }
    }
}
