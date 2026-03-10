// AddWaterView.mc — экран добавления воды + подтверждение + ввод объёма
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// =============================================================================
// Экран выбора порции (3 кнопки + Custom)

class AddWaterView extends WatchUi.View {

    private static const PORTIONS as Array<Number> = [150, 250, 500];
    private static const BTN_COUNT as Number = 4; // 3 порции + Custom

    private var _selected as Number = 1;

    // Параметры кнопок (для tap-определения)
    private var _btnH   as Number = 0;
    private var _startY as Number = 0;
    private var _gapY   as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();
        var h     = dc.getHeight();
        var units = DataStore.getUnits();

        // Сохраняем параметры для tap-детектора
        _btnH   = h * 17 / 100;
        _startY = h * 18 / 100;
        _gapY   = h * 20 / 100;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 9 / 100,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TitleAddWater) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        var btnW = w * 75 / 100;
        var btnX = (w - btnW) / 2;

        for (var i = 0; i < BTN_COUNT; i++) {
            var isActive = (i == _selected);
            var btnY     = _startY + i * _gapY;

            dc.setColor(
                isActive ? 0x0055FF : 0x222222,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRoundedRectangle(btnX, btnY, btnW, _btnH, 8);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                w / 2, btnY + _btnH / 2,
                Graphics.FONT_SMALL,
                _label(i, units),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function selectNext() as Void {
        _selected = (_selected + 1) % BTN_COUNT;
        WatchUi.requestUpdate();
    }

    function selectPrev() as Void {
        _selected = (_selected + BTN_COUNT - 1) % BTN_COUNT;
        WatchUi.requestUpdate();
    }

    // Возвращает индекс кнопки по Y-координате тапа; -1 если мимо
    function getButtonAtY(tapY as Number) as Number {
        for (var i = 0; i < BTN_COUNT; i++) {
            var btnY = _startY + i * _gapY;
            if (tapY >= btnY && tapY <= btnY + _btnH) {
                return i;
            }
        }
        return -1;
    }

    function getSelected() as Number {
        return _selected;
    }

    function setSelected(idx as Number) as Void {
        _selected = idx;
        WatchUi.requestUpdate();
    }

    // Порция выбранной кнопки в мл; -1 = Custom
    function getPortionMl() as Number {
        if (_selected < 3) { return PORTIONS[_selected]; }
        return -1; // Custom
    }

    private function _label(idx as Number, units as Number) as String {
        if (idx < 3) {
            var ml = PORTIONS[idx];
            if (units == 0) { return "+" + ml.toString() + " ml"; }
            return "+" + (ml.toFloat() / 29.5735f).format("%.1f") + " oz";
        }
        return "Custom...";
    }
}

// =============================================================================
// Делегат экрана выбора порции

class AddWaterDelegate extends WatchUi.BehaviorDelegate {

    private var _view      as AddWaterView;
    private var _confirmed as Boolean = false;

    function initialize(view as AddWaterView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // SELECT — подтвердить выбранный вариант
    function onSelect() as Boolean {
        _confirm();
        return true;
    }

    // TAP — найти нажатую кнопку и подтвердить
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var tapY   = coords[1];
        var idx    = _view.getButtonAtY(tapY);
        if (idx >= 0) {
            _view.setSelected(idx);
            _confirm();
        }
        return true;
    }

    // DOWN — следующая кнопка
    function onNextPage() as Boolean {
        _view.selectNext();
        return true;
    }

    // UP — предыдущая кнопка
    function onPreviousPage() as Boolean {
        _view.selectPrev();
        return true;
    }

    // BACK — выход без записи
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function _confirm() as Void {
        if (_confirmed) { return; }
        _confirmed = true;

        var ml = _view.getPortionMl();

        if (ml < 0) {
            // Custom: открыть экран ввода объёма
            _confirmed = false; // разрешить повторный выбор после Custom
            var customView = new CustomAmountView();
            WatchUi.pushView(customView, new CustomAmountDelegate(customView), WatchUi.SLIDE_UP);
        } else {
            var newAmount = DataStore.addAmount(ml);
            var confirmView = new ConfirmView(ml, newAmount);
            WatchUi.pushView(confirmView, new ConfirmDelegate(confirmView), WatchUi.SLIDE_UP);
        }
    }
}

// =============================================================================
// Экран ввода произвольного объёма (Custom)

class CustomAmountView extends WatchUi.View {

    private static const STEP    as Number = 50;
    private static const MIN_ML  as Number = 50;
    private static const MAX_ML  as Number = 2000;

    private var _amount as Number = 200;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();
        var h     = dc.getHeight();
        var units = DataStore.getUnits();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 14 / 100, Graphics.FONT_TINY,
            "Custom", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Стрелка вверх
        dc.setColor(0x0055FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 28 / 100, Graphics.FONT_SMALL,
            "\u25B2", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Объём
        var dispStr = (units == 0)
            ? _amount.toString() + " ml"
            : (_amount.toFloat() / 29.5735f).format("%.0f") + " oz";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 50 / 100, Graphics.FONT_NUMBER_MEDIUM,
            dispStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Стрелка вниз
        dc.setColor(0x0055FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 72 / 100, Graphics.FONT_SMALL,
            "\u25BC", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Подсказка
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 88 / 100, Graphics.FONT_XTINY,
            "SELECT = confirm",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function increase() as Void {
        if (_amount + STEP <= MAX_ML) { _amount += STEP; }
        else { _amount = MAX_ML; }
        WatchUi.requestUpdate();
    }

    function decrease() as Void {
        if (_amount - STEP >= MIN_ML) { _amount -= STEP; }
        else { _amount = MIN_ML; }
        WatchUi.requestUpdate();
    }

    function getAmount() as Number { return _amount; }

    // Верхняя или нижняя половина экрана
    function isUpperHalf(tapY as Number, screenH as Number) as Boolean {
        return tapY < screenH / 2;
    }
}

// Делегат ввода произвольного объёма
class CustomAmountDelegate extends WatchUi.BehaviorDelegate {

    private var _view as CustomAmountView;

    function initialize(view as CustomAmountView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP — увеличить
    function onPreviousPage() as Boolean {
        _view.increase();
        return true;
    }

    // DOWN — уменьшить
    function onNextPage() as Boolean {
        _view.decrease();
        return true;
    }

    // TAP — верхняя половина = +, нижняя = -
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var h = System.getDeviceSettings().screenHeight;
        if (_view.isUpperHalf(coords[1], h)) {
            _view.increase();
        } else {
            _view.decrease();
        }
        return true;
    }

    // SELECT — подтвердить
    function onSelect() as Boolean {
        var ml        = _view.getAmount();
        var newAmount = DataStore.addAmount(ml);
        var confirmView = new ConfirmView(ml, newAmount);
        WatchUi.pushView(confirmView, new ConfirmDelegate(confirmView), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// =============================================================================
// Экран подтверждения добавления

class ConfirmView extends WatchUi.View {

    private var _addedMl as Number;
    private var _totalMl as Number;

    function initialize(added as Number, total as Number) {
        View.initialize();
        _addedMl = added;
        _totalMl = total;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w     = dc.getWidth();
        var h     = dc.getHeight();
        var units = DataStore.getUnits();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Галочка
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 30 / 100, Graphics.FONT_NUMBER_MEDIUM,
            "\u2713", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Добавлено
        var unitStr = (units == 0) ? " ml" : " oz";
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 54 / 100, Graphics.FONT_MEDIUM,
            "+" + _fmt(_addedMl, units) + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Итог / цель
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 72 / 100, Graphics.FONT_TINY,
            _fmt(_totalMl, units) + " / " + _fmt(DataStore.getGoal(), units) + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _fmt(ml as Number, units as Number) as String {
        if (units == 0) { return ml.toString(); }
        return (ml.toFloat() / 29.5735f).format("%.1f");
    }
}

// =============================================================================
// Делегат экрана подтверждения (авто-возврат 2 сек)

class ConfirmDelegate extends WatchUi.BehaviorDelegate {

    private var _timer as Timer.Timer;

    function initialize(view as ConfirmView) {
        BehaviorDelegate.initialize();
        _timer = new Timer.Timer();
        _timer.start(method(:onTimeout), 2000, false);
    }

    function onTimeout() as Void { _popToMain(); }

    function onBack() as Boolean {
        _timer.stop();
        _popToMain();
        return true;
    }

    // Тап по экрану подтверждения тоже закрывает
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        _timer.stop();
        _popToMain();
        return true;
    }

    private function _popToMain() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
