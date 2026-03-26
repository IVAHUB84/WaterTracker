// WaterTrackerApp.mc — точка входа приложения
import Toybox.Application;
import Toybox.Background;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class WaterTrackerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Вызывается при запуске виджета
    function onStart(state as Dictionary?) as Void {
        _ensureReminderScheduled();
    }

    // Вызывается при закрытии виджета
    function onStop(state as Dictionary?) as Void {
    }

    // Вызывается когда пользователь изменил настройки в Garmin Connect
    function onSettingsChanged() as Void {
        _syncPhoneSettings();
        _scheduleReminder();
    }

    // Применяет настройки из Garmin Connect (Application.Properties) → Storage
    private function _syncPhoneSettings() as Void {
        if (!(Application has :Properties)) { return; }
        var units = Application.Properties.getValue("Units");
        if (units instanceof Number) { DataStore.setUnits(units as Number); }
    }

    // Глансовое превью при свайпе по циферблату
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new GlanceView()];
    }

    // Начальный экран
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new WaterTrackerView();
        return [view, new WaterTrackerDelegate(view)];
    }

    // Точка входа фонового сервиса — аннотация обязательна
    (:background)
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new BackgroundService()];
    }

    // Фоновый сервис не передаёт данные обратно
    function onBackgroundData(data as Application.PersistableType) as Void {
    }

    // -------------------------------------------------------------------------
    // Управление расписанием напоминаний

    // Зарегистрировать следующее напоминание согласно настройке интервала
    static function scheduleReminder() as Void {
        _scheduleReminder();
    }

    // Планирует напоминание только если уже нет будущего события.
    // Вызывается из onStart() — не сбивает таймер при каждом открытии виджета.
    private static function _ensureReminderScheduled() as Void {
        if (!(Background has :registerForTemporalEvent)) { return; }
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) { Background.deleteTemporalEvent(); }
            Application.Storage.deleteValue("_nextReminderAt");
            return;
        }
        var nowSec     = _momentSec(Time.now());
        var nextStored = Application.Storage.getValue("_nextReminderAt");
        var storedSec  = (nextStored instanceof Number) ? (nextStored as Number) : -1;
        // Планируем только если нет сохранённого будущего события
        if (storedSec <= nowSec) {
            var next = Time.now().add(new Time.Duration(intervalMin * 60));
            Background.registerForTemporalEvent(next);
            Application.Storage.setValue("_nextReminderAt", _momentSec(next));
        }
    }

    private static function _scheduleReminder() as Void {
        if (!(Background has :registerForTemporalEvent)) { return; }
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) { Background.deleteTemporalEvent(); }
            Application.Storage.deleteValue("_nextReminderAt");
            return;
        }
        var next = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(next);
        Application.Storage.setValue("_nextReminderAt", _momentSec(next));
    }

    // Time.Moment.value() возвращает Long в API 6.0 — приводим к Number для Storage
    private static function _momentSec(m as Time.Moment) as Number {
        var v = m.value();
        return (v instanceof Long) ? (v as Long).toNumber() : (v as Number);
    }
}


// -----------------------------------------------------------------------------
// Глобальный доступ к экземпляру приложения

function getApp() as WaterTrackerApp {
    return Application.getApp() as WaterTrackerApp;
}

// -----------------------------------------------------------------------------
// Публикация данных в Complications (для watchface)

(:complications_api)
function updateComplications() as Void {
    if (!(Toybox has :Complications)) { return; }
    if (!(Complications has :updateComplication)) { return; }

    var units   = DataStore.getUnits();
    var amount  = DataStore.getAmount();
    var goal    = DataStore.getGoal();
    var rec     = DataStore.getBaseRecommendedGoal();

    var isOz    = (units == 1);
    var ml2oz   = 0.033814f;
    var amtVal  = isOz ? (amount * ml2oz).toNumber() : amount;
    var pctVal  = (goal > 0) ? (amount * 100 / goal) : 0;
    var unitStr = isOz ? "oz" : "ml";

    try {
        Complications.updateComplication(0, {:value => amtVal, :unit => unitStr} as Complications.Data);
        Complications.updateComplication(3, {:value => pctVal, :unit => "%"}     as Complications.Data);
        Application.Storage.setValue("_cmpStat", "ok");
    } catch (e instanceof Lang.OperationNotAllowedException) {
        Application.Storage.setValue("_cmpStat", "OpNotAllowed");
    } catch (e instanceof Lang.Exception) {
        Application.Storage.setValue("_cmpStat", e.getErrorMessage());
    }
}

(:no_complications_api)
function updateComplications() as Void {}

