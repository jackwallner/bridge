package com.jackwallner.bridge.ui.theme

import android.app.TimePickerDialog
import android.text.format.DateFormat
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.jackwallner.bridge.data.GameNightDay
import com.jackwallner.bridge.ui.components.symbol
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@Composable
fun BridgeSwitch(checked: Boolean, label: String, modifier: Modifier = Modifier, onChange: (Boolean) -> Unit) {
    val colors = BridgeUI.colors
    Switch(
        checked = checked,
        onCheckedChange = onChange,
        modifier = modifier.semantics { contentDescription = label },
        colors = SwitchDefaults.colors(
            checkedTrackColor = colors.jade,
            checkedThumbColor = Color.White,
            uncheckedTrackColor = colors.well,
            uncheckedBorderColor = colors.rule,
            uncheckedThumbColor = colors.inkTertiary,
        ),
    )
}

/** A settings-style row: label on the left, whatever control on the right. */
@Composable
fun FormRow(
    label: String,
    modifier: Modifier = Modifier,
    icon: String? = null,
    tint: Color = BridgeUI.colors.ink,
    onClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit = {},
) {
    val colors = BridgeUI.colors
    var base = modifier.fillMaxWidth().heightIn(min = 48.dp)
    if (onClick != null) base = base.pressable(onClick = onClick)
    Row(base.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        if (icon != null) Icon(symbol(icon), null, tint = if (tint == colors.ink) colors.jade else tint, modifier = Modifier.size(20.dp))
        Text(label, style = BridgeType.body, color = tint, modifier = Modifier.weight(1f))
        trailing()
    }
}

/** A grouped card of rows with a caption heading, the Android take on an iOS Form section. */
@Composable
fun FormSection(title: String?, modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    val colors = BridgeUI.colors
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        if (title != null) Text(title.uppercase(), style = BridgeType.footnote, color = colors.inkSecondary, modifier = Modifier.padding(start = 16.dp))
        Column(Modifier.fillMaxWidth().background(colors.card, RoundedCornerShape(12.dp)), content = content)
    }
}

@Composable
fun FormDivider() {
    Box(Modifier.fillMaxWidth().padding(start = 16.dp).heightIn(min = 1.dp, max = 1.dp).background(BridgeUI.colors.rule))
}

fun formatTime(hour: Int, minute: Int): String =
    LocalTime.of(hour, minute).format(DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT))

/** A time row that opens the platform time picker. */
@Composable
fun TimePickerRow(label: String, hour: Int, minute: Int, onPick: (Int, Int) -> Unit) {
    val context = LocalContext.current
    val colors = BridgeUI.colors
    Row(Modifier.fillMaxWidth().heightIn(min = 44.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, style = BridgeType.body, color = colors.ink, modifier = Modifier.weight(1f))
        Text(
            formatTime(hour, minute),
            style = BridgeType.body,
            color = colors.jade,
            modifier = Modifier
                .testTag("time-$label")
                .background(colors.well, RoundedCornerShape(8.dp))
                .pressable {
                    TimePickerDialog(context, { _, h, m -> onPick(h, m) }, hour, minute, DateFormat.is24HourFormat(context)).show()
                }
                .padding(horizontal = 10.dp, vertical = 6.dp),
        )
    }
}

@Composable
fun DayPickerRow(day: GameNightDay, onPick: (GameNightDay) -> Unit) {
    val colors = BridgeUI.colors
    var open by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth().heightIn(min = 44.dp), verticalAlignment = Alignment.CenterVertically) {
        Text("Game Night", style = BridgeType.body, color = colors.ink, modifier = Modifier.weight(1f))
        Box {
            Row(
                Modifier.pressable { open = true }.padding(horizontal = 6.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(day.displayName, style = BridgeType.body, color = colors.jade)
                Icon(symbol("chevron.down"), null, tint = colors.jade, modifier = Modifier.size(18.dp))
            }
            DropdownMenu(open, onDismissRequest = { open = false }, containerColor = colors.card) {
                GameNightDay.entries.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option.displayName, style = BridgeType.body, color = colors.ink) },
                        onClick = {
                            open = false
                            onPick(option)
                        },
                    )
                }
            }
        }
    }
}

/** An iOS-style segmented control. */
@Composable
fun <T> Segmented(options: List<T>, selected: T, label: (T) -> String, modifier: Modifier = Modifier, onSelect: (T) -> Unit) {
    val colors = BridgeUI.colors
    Row(modifier.fillMaxWidth().background(colors.well, RoundedCornerShape(9.dp)).padding(2.dp)) {
        options.forEach { option ->
            val isSelected = option == selected
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = 34.dp)
                    .semantics {
                        role = Role.Tab
                        this.selected = isSelected
                    }
                    .background(if (isSelected) colors.card else Color.Transparent, RoundedCornerShape(7.dp))
                    .pressable { onSelect(option) },
                contentAlignment = Alignment.Center,
            ) {
                Text(label(option), style = BridgeType.footnote.copy(fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal), color = colors.ink)
            }
        }
    }
}
