package com.jackwallner.bridge.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.CompareArrows
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.ArrowCircleDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Style
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.EditCalendar
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Paid
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.ViewAgenda
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Filter9Plus
import androidx.compose.material.icons.filled.LibraryAdd
import androidx.compose.material.icons.filled.Tablet
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material.icons.outlined.PlayCircle
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.Shield
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.unit.dp

/** Material has no card suits; this is the spade outline from Material Design Icons (Apache 2.0). */
private val spadeIcon: ImageVector by lazy {
    ImageVector.Builder("Spade", 24.dp, 24.dp, 24f, 24f)
        .addPath(
            PathParser().parsePathString(
                "M12,2C9,7 4,9 4,14C4,16 6,18 8,18C9,18 10,18 11,17C11,17 11.32,19 9,22H15C13,19 13,17 13,17C14,18 15,18 16,18C18,18 20,16 20,14C20,9 15,7 12,2Z",
            ).toNodes(),
            fill = SolidColor(Color.Black),
        )
        .build()
}

/**
 * The SF Symbols the iOS app names, mapped to their closest Material icons.
 * Content and room definitions carry the SF name, so this is the one place
 * the two vocabularies meet.
 */
fun symbol(name: String): ImageVector = when (name) {
    "checkmark" -> Icons.Filled.Check
    "suit.spade.fill" -> spadeIcon
    "quote.bubble.fill" -> Icons.AutoMirrored.Filled.Chat
    "shield.lefthalf.filled" -> Icons.Filled.Shield
    "person.4.fill" -> Icons.Filled.Groups
    "square.stack.3d.up.fill" -> Icons.Filled.Layers
    "rectangle.portrait.on.rectangle.portrait.angled", "rectangle.on.rectangle.angled", "suit.club.fill" -> Icons.Filled.Style
    "arrow.up.right.circle.fill" -> Icons.AutoMirrored.Filled.TrendingUp
    "arrow.down.circle.fill" -> Icons.Filled.ArrowCircleDown
    "figure.walk.motion" -> Icons.Filled.DirectionsRun
    "rectangle.grid.2x2.fill" -> Icons.Filled.Dashboard
    "square.grid.3x3.fill" -> Icons.Filled.GridView
    "menucard.fill", "menucard" -> Icons.AutoMirrored.Filled.MenuBook
    "arrow.triangle.2.circlepath" -> Icons.Filled.Autorenew
    "hand.point.up.left.fill" -> Icons.Filled.TouchApp
    "crown.fill" -> Icons.Filled.WorkspacePremium
    "number.circle.fill" -> Icons.Filled.Filter9Plus
    "flame.fill" -> Icons.Filled.LocalFireDepartment
    "checkmark.seal.fill" -> Icons.Filled.Verified
    "play.circle.fill" -> Icons.Filled.PlayCircle
    "play.circle" -> Icons.Outlined.PlayCircle
    "checkmark.circle.fill" -> Icons.Filled.CheckCircle
    "checkmark.circle" -> Icons.Outlined.CheckCircle
    "circle" -> Icons.Outlined.Circle
    "book.fill", "book.closed.fill" -> Icons.AutoMirrored.Filled.MenuBook
    "book" -> Icons.AutoMirrored.Outlined.MenuBook
    "gearshape" -> Icons.Filled.Settings
    "chevron.right" -> Icons.Filled.ChevronRight
    "chevron.left" -> Icons.Filled.ChevronLeft
    "chevron.down" -> Icons.Filled.ExpandMore
    "lock.fill" -> Icons.Filled.Lock
    "infinity" -> Icons.Filled.AllInclusive
    "calendar.badge.clock" -> Icons.Filled.EditCalendar
    "calendar" -> Icons.Filled.CalendarMonth
    "calendar.badge.checkmark" -> Icons.Filled.EventAvailable
    "person.2.fill" -> Icons.Filled.People
    "person.3.fill" -> Icons.Filled.Groups
    "timer" -> Icons.Filled.Timer
    "arrow.trianglehead.counterclockwise" -> Icons.Filled.Replay
    "sparkles", "sparkle" -> Icons.Filled.AutoAwesome
    "circle.dotted" -> Icons.Outlined.Circle
    "star.fill" -> Icons.Filled.Star
    "star" -> Icons.Filled.StarBorder
    "rectangle.stack.fill" -> Icons.Filled.ViewAgenda
    "questionmark.circle.fill" -> Icons.Filled.Help
    "arrow.left.arrow.right" -> Icons.AutoMirrored.Filled.CompareArrows
    "flag.checkered" -> Icons.Filled.Flag
    "lightbulb.fill" -> Icons.Filled.Lightbulb
    "xmark.circle.fill" -> Icons.Filled.Cancel
    "xmark" -> Icons.Filled.Close
    "hand.tap.fill" -> Icons.Filled.TouchApp
    "hand.draw.fill" -> Icons.Filled.PanTool
    "arrow.uturn.backward" -> Icons.AutoMirrored.Filled.Undo
    "graduationcap.fill" -> Icons.Filled.School
    "target" -> Icons.Filled.TrackChanges
    "scope" -> Icons.Filled.GpsFixed
    "chart.bar.fill" -> Icons.Filled.BarChart
    "magnifyingglass" -> Icons.Filled.Search
    "exclamationmark.triangle.fill" -> Icons.Filled.Warning
    "square.and.arrow.up" -> Icons.Filled.Share
    "envelope.fill" -> Icons.Filled.Email
    "dollarsign.circle.fill" -> Icons.Filled.Paid
    "ipad.landscape" -> Icons.Filled.Tablet
    "plus.rectangle.on.folder.fill" -> Icons.Filled.LibraryAdd
    "figure.walk" -> Icons.Filled.DirectionsWalk
    "tray" -> Icons.Filled.Inbox
    "doc.on.doc" -> Icons.Filled.ContentCopy
    "back" -> Icons.AutoMirrored.Filled.ArrowBack
    else -> Icons.Filled.Star
}
