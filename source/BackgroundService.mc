// BackgroundService.mc — фоновое расписание напоминаний
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

    // Вызывается по расписанию temporal event — просто планирует следующее
    function onTemporalEvent() as Void {
        _scheduleNext();
    }

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
}
