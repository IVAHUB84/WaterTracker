// AddWaterView.mc — экран добавления воды (3 кнопки)
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class AddWaterView extends WatchUi.View {

    // Порции в мл
    private static const PORTIONS = [150, 250, 350] as Array<Number>;
    private var _selected as Number = 1; // по умолчанию средняя кнопка

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Заголовок
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 12 / 100,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TitleAddWater) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Кнопки
        var btnH   = h * 20 / 100;
        var btnW   = w * 70 / 100;
        var btnX   = (w - btnW) / 2;
        var startY = h * 22 / 100;
        var gapY   = h * 24 / 100;

        var units = DataStore.getUnits();

        for (var i = 0; i < 3; i++) {
            var isSelected = (i == _selected);
            var btnY = startY + i * gapY;

            // Фон кнопки
            dc.setColor(
                isSelected ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT
            );
            dc.fillRoundedRectangle(btnX, btnY, btnW, btnH, 8);

            // Текст кнопки
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var label = _portionLabel(PORTIONS[i], units);
            dc.drawText(
                w / 2, btnY + btnH / 2,
                Graphics.FONT_SMALL,
                label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function getSelected() as Number {
        return _selected;
    }

    function selectNext() as Void {
        _selected = (_selected + 1) % 3;
        WatchUi.requestUpdate();
    }

    function selectPrev() as Void {
        _selected = (_selected + 2) % 3; // -1 с wrap
        WatchUi.requestUpdate();
    }

    function getPortionMl() as Number {
        return PORTIONS[_selected];
    }

    private function _portionLabel(ml as Number, units as Number) as String {
        if (units == 0) {
            return "+" + ml.toString() + " ml";
        }
        var oz = (ml * 10 / 296).toFloat() / 10.0;
        return "+" + oz.format("%.1f") + " oz";
    }
}

// Делегат экрана добавления
class AddWaterDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AddWaterView;
    private var _confirmed as Boolean = false;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = WatchUi.getCurrentView()[0] as AddWaterView;
    }

    // SELECT — подтвердить выбранную порцию
    function onSelect() as Boolean {
        if (_confirmed) { return true; }
        _confirmed = true;

        var ml = _view.getPortionMl();
        var newAmount = DataStore.addAmount(ml);

        // Показать экран подтверждения
        WatchUi.pushView(
            new ConfirmView(ml, newAmount),
            new ConfirmDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    // UP / DOWN — переключение кнопок
    function onPreviousPage() as Boolean {
        _view.selectPrev();
        return true;
    }

    function onNextPage() as Boolean {
        _view.selectNext();
        return true;
    }

    // BACK — назад на главный экран
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

// Экран подтверждения добавления
class ConfirmView extends WatchUi.View {

    private var _addedMl  as Number;
    private var _totalMl  as Number;

    function initialize(added as Number, total as Number) {
        View.initialize();
        _addedMl = added;
        _totalMl = total;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var units = DataStore.getUnits();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Иконка галочки
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 35 / 100,
            Graphics.FONT_NUMBER_MEDIUM,
            "+",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Добавлено X мл
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var addedLabel = _formatAmount(_addedMl, units);
        var unitStr    = (units == 0) ? " ml" : " oz";
        dc.drawText(
            w / 2, h * 55 / 100,
            Graphics.FONT_MEDIUM,
            "+" + addedLabel + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Новый итог
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2, h * 72 / 100,
            Graphics.FONT_TINY,
            _formatAmount(_totalMl, units) + unitStr + " / " +
            _formatAmount(DataStore.getGoal(), units) + unitStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function _formatAmount(ml as Number, units as Number) as String {
        if (units == 0) { return ml.toString(); }
        var oz = (ml * 10 / 296).toFloat() / 10.0;
        return oz.format("%.1f");
    }
}

// Делегат экрана подтверждения (авто-возврат через 2 сек)
class ConfirmDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
        // Авто-возврат через 2 секунды
        // Реализуется через Timer в onShow или таймер в App
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
