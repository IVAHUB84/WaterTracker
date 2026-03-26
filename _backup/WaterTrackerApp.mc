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
    // При первом запуске авто-устанавливаем цель из профиля пользователя
    function onStart(state as Dictionary?) as Void {
    }

    // Вызывается при закрытии виджета
    function onStop(state as Dictionary?) as Void {
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

    private static function _scheduleReminder() as Void {
        if (!(Background has :registerForTemporalEvent)) {
            return;
        }
        var intervalMin = DataStore.getInterval();
        if (intervalMin <= 0) {
            if (Background has :deleteTemporalEvent) {
                Background.deleteTemporalEvent();
            }
            return;
        }
        var nextEvent = Time.now().add(new Time.Duration(intervalMin * 60));
        Background.registerForTemporalEvent(nextEvent);
    }
}

// -----------------------------------------------------------------------------
// Делегат кнопок главного экрана

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

    // MENU (долгое нажатие UP) — редактирование цели
    function onMenu() as Boolean {
        pushGoalPickerView();
        return true;
    }

    // Физ. кнопки UP/DOWN — перемещение выделения (Instinct) / прокрутка (touch)
    function onPreviousPage() as Boolean {
        _view.moveSelectionUp();
        return true;
    }

    function onNextPage() as Boolean {
        _view.moveSelectionDown();
        return true;
    }

    // SELECT — активировать выделенный пункт (Instinct)
    function onSelect() as Boolean {
        if (!_view.hasKeyFocus()) { return false; }
        var itemIdx = _view.getSelectedItemIdx();
        _view.flashZone(_view.getSelectedSlot());
        if      (itemIdx == 0) { DataStore.addAmount(-100); updateComplications(); }
        else if (itemIdx == 1) { DataStore.addAmount(100);  updateComplications(); }
        else if (itemIdx == 2) { DataStore.addAmount(250);  updateComplications(); }
        else if (itemIdx == 3) { DataStore.addAmount(500);  updateComplications(); }
        else if (itemIdx == 4) { pushQuickAddView(); }
        else if (itemIdx == 5) { pushResetConfirm(); }
        WatchUi.requestUpdate();
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
        // Большой скачок = начало нового жеста, просто запомнить
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

        if (zone == ZONE_SCROLL_UP)   { _view.scrollUp();                    return true; }
        if (zone == ZONE_SCROLL_DOWN) { _view.scrollDown();                   return true; }
        if (zone == ZONE_WARNING)     { pushProfileWarningView();             return true; }


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

// -----------------------------------------------------------------------------
// Глобальный доступ к экземпляру приложения

function getApp() as WaterTrackerApp {
    return Application.getApp() as WaterTrackerApp;
}

// -----------------------------------------------------------------------------
// Публикация данных в Complications (для watchface)

function updateComplications() as Void {
    if (!(Toybox has :Complications)) {
        Application.Storage.setValue("_cmpStat", "no module");
        return;
    }
    var units   = DataStore.getUnits();
    var amount  = DataStore.getAmount();
    var goal    = DataStore.getGoal();
    var rec     = DataStore.getBaseRecommendedGoal();

    var isOz    = (units == 1);
    var ml2oz   = 0.033814f;
    var amtVal  = isOz ? (amount * ml2oz) : amount.toFloat();
    var goalVal = isOz ? (goal   * ml2oz) : goal.toFloat();
    var recVal  = isOz ? (rec    * ml2oz) : rec.toFloat();
    var pctVal  = (goal > 0) ? (amount * 100.0f / goal) : 0.0f;
    var unitStr = isOz ? "oz" : "ml";

    try {
        Complications.updateComplication(0, {:value => amtVal,  :unit => unitStr} as Complications.Data);
        Complications.updateComplication(1, {:value => goalVal, :unit => unitStr} as Complications.Data);
        Complications.updateComplication(2, {:value => recVal,  :unit => unitStr} as Complications.Data);
        Complications.updateComplication(3, {:value => pctVal,  :unit => "%"} as Complications.Data);
        Application.Storage.setValue("_cmpStat", "ok");
    } catch (e instanceof Lang.OperationNotAllowedException) {
        Application.Storage.setValue("_cmpStat", "OpNotAllowed");
    } catch (e instanceof Lang.Exception) {
        Application.Storage.setValue("_cmpStat", e.getErrorMessage());
    }
}

