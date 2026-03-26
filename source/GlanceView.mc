// GlanceView.mc — превью виджета при свайпе по циферблату
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class GlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var amount  = DataStore.getAmount();
        var rec     = DataStore.getRecommendedGoal();
        var units   = DataStore.getUnits();
        var isOz    = (units == 1);
        var ml2oz   = 0.033814f;

        var amtDisp = isOz ? (amount * ml2oz).toNumber() : amount;
        var unitLbl = isOz ? "oz" : "ml";

        // Прогресс [0..1]
        var pct = (rec > 0) ? (amount.toFloat() / rec.toFloat()) : 0.0f;
        if (pct > 1.0f) { pct = 1.0f; }
        var pctInt = (pct * 100.0f).toNumber();

        // Цвет по прогрессу
        var fillColor;
        if (amount >= rec)                      { fillColor = 0x1565C0; }
        else if (amount >= DataStore.getGoal()) { fillColor = 0x43A047; }
        else if (pct >= 0.33f)                  { fillColor = 0xFF8F00; }
        else                                    { fillColor = 0xE0E0E0; }

        var recReached = (amount >= rec);
        var labelColor = recReached ? 0x1565C0 : 0x505050;

        var jC = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var jL = Graphics.TEXT_JUSTIFY_LEFT   | Graphics.TEXT_JUSTIFY_VCENTER;
        var jR = Graphics.TEXT_JUSTIFY_RIGHT  | Graphics.TEXT_JUSTIFY_VCENTER;

        var barX = w * 2 / 100;
        var barW = w * 84 / 100;
        var barH = h * 16 / 100;
        if (barH < 6) { barH = 6; }
        var barR = barH / 2;
        var barY = (h - barH) / 2;  // точно по центру

        var topY = h * 17 / 100;    // верхний край (ближе к центру на 10%)
        var botY = h * 83 / 100;    // нижний край (ближе к центру на 10%)

        // ── Строка сверху: TODAY слева, 52% REC справа ────────
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barX, topY, Graphics.FONT_XTINY, "TODAY", jL);
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barX + barW, topY, Graphics.FONT_XTINY,
            pctInt.toString() + "% REC", jR);

        // ── Прогресс бар по центру ────────────────────────────
        var trackH = 2;
        var trackY = barY + (barH - trackH) / 2;
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, trackY, barW, trackH, 1);

        var fillW = (barW * pct).toNumber();
        if (fillW > 0) {
            if (fillW < barH) { fillW = barH; }
            if (fillW > barW) { fillW = barW; }
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, barY, fillW, barH, barR);
        }

        // ── Строка снизу: количество слева, REC справа ────────
        var recDisp = isOz ? (rec * ml2oz).toNumber() : rec;
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barX, botY, Graphics.FONT_XTINY,
            amtDisp.toString() + " " + unitLbl, jL);
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barX + barW, botY, Graphics.FONT_XTINY,
            recDisp.toString() + " " + unitLbl, jR);
    }
}
