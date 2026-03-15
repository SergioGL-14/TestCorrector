# =============================================================================
# TestCorrector.ps1  —  Motor de test dinamico
# PowerShell + WPF sin XAML
# =============================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# =============================================================================
# BLOQUE 1: ESTADO GLOBAL
# =============================================================================

$Script:Questions   = [System.Collections.Generic.List[PSObject]]::new()
$Script:AnswerKeys  = @{}
# UIState: num -> { Badge, BadgeTxt, OptionBorders{}, OptionTexts{}, Selected }
$Script:UIState     = @{}

# =============================================================================
# BLOQUE 2: PALETA DE COLORES
# =============================================================================

function rgb($r,$g,$b) {
    [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.Color]::FromRgb($r,$g,$b))
}

$C = @{
    Bg         = (rgb 15  15  23)
    Surface    = (rgb 22  22  35)
    Card       = (rgb 30  30  48)
    CardHover  = (rgb 38  38  60)
    OptNormal  = (rgb 26  26  42)
    OptSel     = (rgb 48  48  90)
    OptCorrect = (rgb 22  80  45)
    OptWrong   = (rgb 80  22  30)
    Accent     = (rgb 99  102 241)
    Green      = (rgb 34  197 94)
    Red        = (rgb 239 68  68)
    Yellow     = (rgb 250 200 50)
    TxtPri     = (rgb 240 240 255)
    TxtSec     = (rgb 160 160 200)
    TxtMut     = (rgb 90  90  130)
    Border     = (rgb 50  50  80)
    BorderSel  = (rgb 99  102 241)
}

# =============================================================================
# BLOQUE 3: PARSER
# =============================================================================

function Parse-Questions([string]$raw) {
    $list    = [System.Collections.Generic.List[PSObject]]::new()
    $lines   = $raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $cur     = $null
    $autoNum = 0

    foreach ($line in $lines) {

        # ---- Opcion: empieza por A/B/C/D seguido de ) o . ----
        if ($line -match '^([A-Da-d])\s*[.)]\s*(.+)$') {
            if ($null -ne $cur) {
                $cur.Options.Add([PSCustomObject]@{
                    Letter = $Matches[1].ToUpper()
                    Text   = $Matches[2].Trim()
                })
            }
            continue
        }

        # ---- Enunciado: cualquier linea que no empiece por digito ni por letra de opcion ----
        if ($line -notmatch '^\d') {
            if ($cur -and $cur.Options.Count -gt 0) {
                # Pregunta anterior completa: guardarla y empezar nueva
                $list.Add($cur)
                $autoNum = $list.Count
                $cur = [PSCustomObject]@{
                    Number  = $autoNum + 1
                    Text    = $line
                    Options = [System.Collections.Generic.List[PSObject]]::new()
                }
            } elseif ($null -eq $cur) {
                # Primera pregunta
                $autoNum++
                $cur = [PSCustomObject]@{
                    Number  = $autoNum
                    Text    = $line
                    Options = [System.Collections.Generic.List[PSObject]]::new()
                }
            } else {
                # Continuacion del enunciado actual (enunciado multilinea)
                $cur.Text += ' ' + $line
            }
            continue
        }
    }

    # Ultima pregunta
    if ($cur -and $cur.Options.Count -gt 0) { $list.Add($cur) }

    return $list
}

function Parse-AnswerKey([string]$raw) {
    $keys = @{}
    # Acepta: 1.B  1:B  1-B  1)B  con o sin espacios, multilinea
    $ms = [regex]::Matches($raw, '(\d+)\s*[.\-:)]\s*([A-Da-d])')
    foreach ($m in $ms) {
        $keys[[int]$m.Groups[1].Value] = $m.Groups[2].Value.ToUpper()
    }
    # Fallback: "1B 2C" sin separador
    if ($keys.Count -eq 0) {
        $ms2 = [regex]::Matches($raw, '(\d+)\s+([A-Da-d])(?=\s|$)')
        foreach ($m in $ms2) {
            $keys[[int]$m.Groups[1].Value] = $m.Groups[2].Value.ToUpper()
        }
    }
    return $keys
}

# =============================================================================
# BLOQUE 4: HELPERS DE CONTROLES
# =============================================================================

function New-TB([string]$text, [double]$size, $fg, [bool]$bold=$false, [bool]$wrap=$false) {
    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text       = $text
    $tb.FontSize   = $size
    $tb.Foreground = $fg
    if ($bold) { $tb.FontWeight   = [System.Windows.FontWeights]::SemiBold }
    if ($wrap) { $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap }
    return $tb
}

function New-VBorder($bg, $radius=0, $bBrush=$null, $bThick=0) {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background   = $bg
    $b.CornerRadius = [System.Windows.CornerRadius]::new($radius)
    if ($bBrush) {
        $b.BorderBrush     = $bBrush
        $b.BorderThickness = [System.Windows.Thickness]::new($bThick)
    }
    return $b
}

function New-Btn([string]$label, $bg, [double]$w=0) {
    $btn = [System.Windows.Controls.Button]::new()
    $btn.Content    = $label
    $btn.Height     = 36
    $btn.Padding    = [System.Windows.Thickness]::new(18,0,18,0)
    $btn.FontSize   = 12
    $btn.FontWeight = [System.Windows.FontWeights]::SemiBold
    $btn.Foreground = $C.TxtPri
    $btn.Background = $bg
    $btn.BorderThickness = [System.Windows.Thickness]::new(0)
    $btn.Cursor     = [System.Windows.Input.Cursors]::Hand
    if ($w -gt 0) { $btn.Width = $w }

    $tpl = [System.Windows.Controls.ControlTemplate]::new([System.Windows.Controls.Button])
    $fac = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Border])
    $fac.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(7))
    $fac.SetBinding([System.Windows.Controls.Border]::BackgroundProperty,
        [System.Windows.Data.Binding]::new("Background"))
    $cp = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.ContentPresenter])
    $cp.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty,
        [System.Windows.HorizontalAlignment]::Center)
    $cp.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty,
        [System.Windows.VerticalAlignment]::Center)
    $fac.AppendChild($cp)
    $tpl.VisualTree = $fac
    $sty = [System.Windows.Style]::new([System.Windows.Controls.Button])
    $sty.Setters.Add([System.Windows.Setter]::new(
        [System.Windows.Controls.Control]::TemplateProperty, $tpl))
    $btn.Style = $sty
    return $btn
}

function New-HStack() {
    $s = [System.Windows.Controls.StackPanel]::new()
    $s.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    return $s
}

function New-VStack() {
    $s = [System.Windows.Controls.StackPanel]::new()
    $s.Orientation = [System.Windows.Controls.Orientation]::Vertical
    return $s
}

function Add-Row($g, $h) {
    $rd = [System.Windows.Controls.RowDefinition]::new()
    if    ($h -eq '*')    { $rd.Height = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star) }
    elseif($h -eq 'Auto') { $rd.Height = [System.Windows.GridLength]::Auto }
    else                  { $rd.Height = [System.Windows.GridLength]::new([double]$h) }
    $g.RowDefinitions.Add($rd)
}

function Add-Col($g, $w) {
    $cd = [System.Windows.Controls.ColumnDefinition]::new()
    if    ($w -eq '*')    { $cd.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star) }
    elseif($w -eq 'Auto') { $cd.Width = [System.Windows.GridLength]::Auto }
    else                  { $cd.Width = [System.Windows.GridLength]::new([double]$w) }
    $g.ColumnDefinitions.Add($cd)
}

function GPos($el,$r,$c) {
    [System.Windows.Controls.Grid]::SetRow($el,$r)
    [System.Windows.Controls.Grid]::SetColumn($el,$c)
}

function New-TextArea([double]$h, [string]$ph) {
    $tb = [System.Windows.Controls.TextBox]::new()
    $tb.Height     = $h
    $tb.AcceptsReturn = $true
    $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $tb.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $tb.Background  = $C.Card
    $tb.Foreground  = $C.TxtMut
    $tb.CaretBrush  = $C.TxtPri
    $tb.BorderBrush = $C.Border
    $tb.BorderThickness = [System.Windows.Thickness]::new(1)
    $tb.Padding     = [System.Windows.Thickness]::new(8)
    $tb.FontFamily  = [System.Windows.Media.FontFamily]::new("Consolas")
    $tb.FontSize    = 11
    $tb.Text        = $ph
    $placeholder    = $ph

    $tb.Add_GotFocus({
        if ($this.Foreground.Color -eq $C.TxtMut.Color) {
            $this.Text = ""
            $this.Foreground = $C.TxtPri
        }
    })
    $tb.Add_LostFocus({
        if ($this.Text.Trim() -eq "") {
            $this.Text = $placeholder
            $this.Foreground = $C.TxtMut
        }
    })
    return $tb
}

function New-HSep([double]$m=8) {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background = $C.Border
    $b.Height     = 1
    $b.Margin     = [System.Windows.Thickness]::new(0,$m,0,$m)
    return $b
}

function SectionLabel([string]$t) {
    $tb = New-TB $t 10 $C.TxtMut $true
    return $tb
}

# =============================================================================
# BLOQUE 5: VENTANA PRINCIPAL
# =============================================================================

function New-MainWindow {
    $w = [System.Windows.Window]::new()
    $w.Title      = "TestCorrector"
    $w.Width      = 1180
    $w.Height     = 840
    $w.MinWidth   = 900
    $w.MinHeight  = 600
    $w.Background = $C.Bg
    $w.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $w.FontSize   = 13
    $w.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen

    $root = [System.Windows.Controls.Grid]::new()
    Add-Row $root 64
    Add-Row $root '*'
    Add-Row $root 58

    $hdr  = Build-Header
    $body = Build-Content
    $ftr  = Build-Footer

    GPos $hdr  0 0
    GPos $body 1 0
    GPos $ftr  2 0

    $root.Children.Add($hdr)  | Out-Null
    $root.Children.Add($body) | Out-Null
    $root.Children.Add($ftr)  | Out-Null

    $w.Content = $root
    return $w
}

# =============================================================================
# BLOQUE 6: HEADER
# =============================================================================

function Build-Header {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background  = $C.Surface
    $b.BorderBrush = $C.Border
    $b.BorderThickness = [System.Windows.Thickness]::new(0,0,0,1)
    $b.Padding     = [System.Windows.Thickness]::new(24,0,16,0)

    $g = [System.Windows.Controls.Grid]::new()
    Add-Col $g '*'
    Add-Col $g 'Auto'
    Add-Col $g 'Auto'

    # --- Izquierda: logo + titulo ---
    $left = New-HStack
    $left.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $ico = New-TB "📝" 26 $C.TxtPri
    $ico.Margin = [System.Windows.Thickness]::new(0,0,12,0)
    $ico.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $vt = New-VStack
    $t1 = New-TB "TestCorrector" 19 $C.Accent $true
    $t2 = New-TB "Motor de test dinámico" 11 $C.TxtMut
    $vt.Children.Add($t1) | Out-Null
    $vt.Children.Add($t2) | Out-Null

    $left.Children.Add($ico) | Out-Null
    $left.Children.Add($vt)  | Out-Null

    # --- Centro: progreso ---
    $Script:HdrProgress = New-TB "" 12 $C.TxtSec
    $Script:HdrProgress.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $Script:HdrProgress.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
    $Script:HdrProgress.Margin = [System.Windows.Thickness]::new(0,0,24,0)

    # --- Derecha: zoom controls ---
    $zoomPanel = New-HStack
    $zoomPanel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $zoomLbl = New-TB "🔍" 14 $C.TxtMut
    $zoomLbl.Margin = [System.Windows.Thickness]::new(0,0,6,0)
    $zoomLbl.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $Script:ZoomSlider = [System.Windows.Controls.Slider]::new()
    $Script:ZoomSlider.Minimum        = 0.6
    $Script:ZoomSlider.Maximum        = 2.0
    $Script:ZoomSlider.Value          = 1.2
    $Script:ZoomSlider.Width          = 110
    $Script:ZoomSlider.TickFrequency  = 0.1
    $Script:ZoomSlider.SmallChange    = 0.05
    $Script:ZoomSlider.LargeChange    = 0.2
    $Script:ZoomSlider.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $Script:ZoomLabel = New-TB "100%" 11 $C.TxtSec
    $Script:ZoomLabel.Width  = 38
    $Script:ZoomLabel.Margin = [System.Windows.Thickness]::new(6,0,4,0)
    $Script:ZoomLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $btnZoomReset = New-Btn "1:1" (rgb 50 50 80) 32
    $btnZoomReset.Height = 26
    $btnZoomReset.FontSize = 10
    $btnZoomReset.Add_Click({ Apply-Zoom 1.0 })

    $Script:ZoomSlider.Add_ValueChanged({
        Apply-Zoom $Script:ZoomSlider.Value
    })

    $zoomPanel.Children.Add($zoomLbl)         | Out-Null
    $zoomPanel.Children.Add($Script:ZoomSlider) | Out-Null
    $zoomPanel.Children.Add($Script:ZoomLabel)  | Out-Null
    $zoomPanel.Children.Add($btnZoomReset)      | Out-Null

    GPos $left                0 0
    GPos $Script:HdrProgress  0 1
    GPos $zoomPanel           0 2

    $g.Children.Add($left)               | Out-Null
    $g.Children.Add($Script:HdrProgress) | Out-Null
    $g.Children.Add($zoomPanel)          | Out-Null

    $b.Child = $g
    return $b
}

# =============================================================================
# BLOQUE 7: CONTENT
# =============================================================================

function Build-Content {
    $g = [System.Windows.Controls.Grid]::new()
    Add-Col $g 300
    Add-Col $g 5
    Add-Col $g '*'

    $left = Build-LeftPanel

    $gs = [System.Windows.Controls.GridSplitter]::new()
    $gs.Width = 5
    $gs.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $gs.VerticalAlignment   = [System.Windows.VerticalAlignment]::Stretch
    $gs.Background          = $C.Border
    $gs.ShowsPreview        = $true

    $right = Build-RightPanel

    GPos $left  0 0
    GPos $gs    0 1
    GPos $right 0 2

    $g.Children.Add($left)  | Out-Null
    $g.Children.Add($gs)    | Out-Null
    $g.Children.Add($right) | Out-Null

    return $g
}

# =============================================================================
# BLOQUE 8: PANEL IZQUIERDO
# =============================================================================

function Build-LeftPanel {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background  = $C.Surface
    $b.BorderBrush = $C.Border
    $b.BorderThickness = [System.Windows.Thickness]::new(0,0,1,0)

    $sv = [System.Windows.Controls.ScrollViewer]::new()
    $sv.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $sv.Padding = [System.Windows.Thickness]::new(16)

    $sp = New-VStack

    # ---- Preguntas ----
    $sp.Children.Add((SectionLabel "PREGUNTAS")) | Out-Null

    $Script:TxtQ = New-TextArea 185 "Pega aquí las preguntas tipo test...`n`nFormato:`n1. Enunciado`nA) Opcion A`nB) Opcion B`nC) Opcion C`nD) Opcion D"
    $Script:TxtQ.Margin = [System.Windows.Thickness]::new(0,6,0,8)

    $rBtns = New-HStack
    $btnLoad = New-Btn "▶  Cargar texto" $C.Accent
    $btnLoad.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnLoad.Add_Click({ Action-LoadText })

    $btnFile = New-Btn "📂  Abrir .txt" (rgb 55 55 90)
    $btnFile.Margin = [System.Windows.Thickness]::new(6,0,0,0)
    $btnFile.Add_Click({ Action-OpenFile })

    $rBtns.Children.Add($btnLoad) | Out-Null
    $rBtns.Children.Add($btnFile) | Out-Null

    $Script:LblQSt = New-TB "" 11 $C.TxtMut
    $Script:LblQSt.Margin = [System.Windows.Thickness]::new(0,6,0,0)
    $Script:LblQSt.TextWrapping = [System.Windows.TextWrapping]::Wrap

    $sp.Children.Add($Script:TxtQ)   | Out-Null
    $sp.Children.Add($rBtns)         | Out-Null
    $sp.Children.Add($Script:LblQSt) | Out-Null

    # ---- Separador ----
    $sp.Children.Add((New-HSep 14)) | Out-Null

    # ---- Clave ----
    $sp.Children.Add((SectionLabel "CLAVE DE RESPUESTAS")) | Out-Null

    $hint = New-TB "Carga desde archivo .txt o pega el texto completo." 10 $C.TxtMut
    $hint.Margin = [System.Windows.Thickness]::new(0,2,0,8)
    $hint.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $sp.Children.Add($hint) | Out-Null

    # Boton principal: cargar desde archivo (recomendado — no trunca)
    $btnKeyFile = New-Btn "📂  Cargar clave desde .txt" (rgb 30 100 55)
    $btnKeyFile.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnKeyFile.Margin = [System.Windows.Thickness]::new(0,0,0,8)
    $btnKeyFile.Add_Click({ Action-OpenKeyFile })
    $sp.Children.Add($btnKeyFile) | Out-Null

    # Alternativa: pegar texto — TextBox multilinea (acepta saltos de linea, no trunca)
    $Script:RealKeyText = ""
    $Script:TxtKeyVisible = New-TextArea 60 "O pega aquí: 1.B 2.C 3.A ..."
    $Script:TxtKeyVisible.Margin = [System.Windows.Thickness]::new(0,0,0,6)
    $sp.Children.Add($Script:TxtKeyVisible) | Out-Null

    $btnKey = New-Btn "✓  Usar texto pegado" (rgb 55 90 55)
    $btnKey.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnKey.Add_Click({ Action-LoadKey })
    $sp.Children.Add($btnKey) | Out-Null

    $Script:LblKSt = New-TB "" 11 $C.TxtMut
    $Script:LblKSt.Margin = [System.Windows.Thickness]::new(0,6,0,0)
    $Script:LblKSt.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $sp.Children.Add($Script:LblKSt) | Out-Null

    # ---- Separador ----
    $sp.Children.Add((New-HSep 14)) | Out-Null

    # ---- Acciones ----
    $sp.Children.Add((SectionLabel "ACCIONES")) | Out-Null
    $sp.Children.Add((New-HSep 4))              | Out-Null

    $btnCorrect = New-Btn "🎯  Corregir test" $C.Accent
    $btnCorrect.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnCorrect.Margin = [System.Windows.Thickness]::new(0,4,0,6)
    $btnCorrect.Add_Click({ Action-Correct })

    $btnReset = New-Btn "↺  Reiniciar respuestas" (rgb 70 40 40)
    $btnReset.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnReset.Margin = [System.Windows.Thickness]::new(0,0,0,6)
    $btnReset.Add_Click({ Action-Reset })

    $btnClear = New-Btn "🗑  Limpiar todo" (rgb 50 25 25)
    $btnClear.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
    $btnClear.Add_Click({ Action-ClearAll })

    $sp.Children.Add($btnCorrect) | Out-Null
    $sp.Children.Add($btnReset)   | Out-Null
    $sp.Children.Add($btnClear)   | Out-Null

    $sv.Content = $sp
    $b.Child    = $sv
    return $b
}

# =============================================================================
# BLOQUE 9: PANEL DERECHO
# =============================================================================

function Build-RightPanel {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background = $C.Bg

    $Script:SV = [System.Windows.Controls.ScrollViewer]::new()
    $Script:SV.VerticalScrollBarVisibility   = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $Script:SV.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled
    $Script:SV.Padding = [System.Windows.Thickness]::new(18,14,18,14)

    # Ctrl + Rueda del raton = zoom
    $Script:SV.Add_PreviewMouseWheel({
        if ([System.Windows.Input.Keyboard]::IsKeyDown(
                [System.Windows.Input.Key]::LeftCtrl) -or
            [System.Windows.Input.Keyboard]::IsKeyDown(
                [System.Windows.Input.Key]::RightCtrl)) {
            $delta = if ($_.Delta -gt 0) { 0.1 } else { -0.1 }
            Apply-Zoom ($Script:CurrentZoom + $delta)
            $_.Handled = $true
        }
    })

    $Script:QPanel = [System.Windows.Controls.WrapPanel]::new()
    $Script:QPanel.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $Script:QPanel.ItemWidth   = 370   # ancho fijo por celda, el card tiene padding interno

    $Script:SV.Content = Build-EmptyState
    $b.Child = $Script:SV
    return $b
}

function Build-EmptyState {
    $sp = New-VStack
    $sp.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $sp.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $sp.Margin = [System.Windows.Thickness]::new(0,80,0,0)

    $ico = New-TB "📋" 52 $C.TxtMut
    $ico.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    $t1 = New-TB "Sin preguntas cargadas" 18 $C.TxtMut $true
    $t1.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $t1.Margin = [System.Windows.Thickness]::new(0,12,0,6)

    $t2 = New-TB "Pega el texto o abre un .txt desde el panel izquierdo." 13 $C.TxtMut $false $true
    $t2.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $t2.TextAlignment = [System.Windows.TextAlignment]::Center

    $sp.Children.Add($ico) | Out-Null
    $sp.Children.Add($t1)  | Out-Null
    $sp.Children.Add($t2)  | Out-Null
    return $sp
}

# =============================================================================
# BLOQUE 10: FOOTER
# =============================================================================

function Build-Footer {
    $b = [System.Windows.Controls.Border]::new()
    $b.Background  = $C.Surface
    $b.BorderBrush = $C.Border
    $b.BorderThickness = [System.Windows.Thickness]::new(0,1,0,0)
    $b.Padding     = [System.Windows.Thickness]::new(24,0,24,0)

    $g = [System.Windows.Controls.Grid]::new()
    Add-Col $g '*'
    Add-Col $g 'Auto'

    $Script:FooterMsg = New-TB "Carga las preguntas para comenzar." 12 $C.TxtSec
    $Script:FooterMsg.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $Script:FooterMsg.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")

    $btnExp = New-Btn "📋  Exportar respuestas" $C.Accent
    $btnExp.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $btnExp.Add_Click({ Action-Export })

    GPos $Script:FooterMsg 0 0
    GPos $btnExp           0 1

    $g.Children.Add($Script:FooterMsg) | Out-Null
    $g.Children.Add($btnExp)           | Out-Null

    $b.Child = $g
    return $b
}

# =============================================================================
# BLOQUE 11: TARJETA DE PREGUNTA
# =============================================================================

function Build-QuestionCard([PSObject]$q) {
    $num = $q.Number

    $card = New-VBorder $C.Card 9 $C.Border 1
    $card.Margin  = [System.Windows.Thickness]::new(5)
    $card.Padding = [System.Windows.Thickness]::new(14,12,14,14)
    $card.Width   = 360
    # Alto minimo pero sin altura fija — crece con el contenido
    $card.MinHeight = 0

    $vs = New-VStack

    # --- Cabecera: badge + enunciado en layout grid para que el texto use todo el ancho ---
    $hdrGrid = [System.Windows.Controls.Grid]::new()
    Add-Col $hdrGrid 'Auto'  # badge
    Add-Col $hdrGrid '*'     # texto (toma el resto)
    $hdrGrid.Margin = [System.Windows.Thickness]::new(0,0,0,10)

    $badge = New-VBorder $C.Accent 5
    $badge.Padding = [System.Windows.Thickness]::new(7,3,7,3)
    $badge.Margin  = [System.Windows.Thickness]::new(0,2,10,0)
    $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $bTxt = New-TB "$num" 11 $C.TxtPri $true
    $badge.Child = $bTxt

    $qTxt = New-TB $q.Text 12 $C.TxtPri $true $true
    $qTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Top

    [System.Windows.Controls.Grid]::SetColumn($badge, 0)
    [System.Windows.Controls.Grid]::SetColumn($qTxt,  1)
    $hdrGrid.Children.Add($badge) | Out-Null
    $hdrGrid.Children.Add($qTxt)  | Out-Null

    $sep = [System.Windows.Controls.Border]::new()
    $sep.Height     = 1
    $sep.Background = $C.Border
    $sep.Margin     = [System.Windows.Thickness]::new(0,0,0,8)

    $vs.Children.Add($hdrGrid) | Out-Null
    $vs.Children.Add($sep)     | Out-Null

    # Inicializar estado
    $Script:UIState[$num] = @{
        Badge         = $badge
        BadgeTxt      = $bTxt
        OptionBorders = @{}
        OptionTexts   = @{}
        Selected      = $null
    }

    # --- Opciones ---
    foreach ($opt in $q.Options) {
        $ob = Build-OptionRow $num $opt.Letter $opt.Text
        $vs.Children.Add($ob) | Out-Null
    }

    $card.Child = $vs
    return $card
}

function Build-OptionRow([int]$qNum, [string]$letter, [string]$text) {
    $ob = New-VBorder $C.OptNormal 6
    $ob.Padding = [System.Windows.Thickness]::new(10,7,10,7)
    $ob.Margin  = [System.Windows.Thickness]::new(0,2,0,2)
    $ob.Cursor  = [System.Windows.Input.Cursors]::Hand
    $ob.Tag     = "$qNum|$letter"   # <-- datos en Tag, SIN closures sobre variables mutables

    $row = New-HStack

    $lb = New-VBorder (rgb 45 45 70) 4
    $lb.Width  = 24
    $lb.Height = 24
    $lb.Margin = [System.Windows.Thickness]::new(0,0,9,0)
    $lb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $lTxt = New-TB $letter 10 $C.TxtSec $true
    $lTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $lTxt.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center
    $lb.Child = $lTxt

    $oTxt = New-TB $text 11 $C.TxtSec $false $true
    $oTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

    $row.Children.Add($lb)   | Out-Null
    $row.Children.Add($oTxt) | Out-Null
    $ob.Child = $row

    # Guardar referencias
    $Script:UIState[$qNum].OptionBorders[$letter] = $ob
    $Script:UIState[$qNum].OptionTexts[$letter]   = $oTxt

    # Eventos: leer datos desde Tag, sin capturar variables locales
    $ob.Add_MouseLeftButtonDown({
        $p = $this.Tag -split '\|'
        Select-Option ([int]$p[0]) $p[1]
    })
    $ob.Add_MouseEnter({
        $p = $this.Tag -split '\|'
        $qn = [int]$p[0]; $lt = $p[1]
        if ($Script:UIState[$qn].Selected -ne $lt) {
            $this.Background = $C.CardHover
        }
    })
    $ob.Add_MouseLeave({
        $p = $this.Tag -split '\|'
        $qn = [int]$p[0]; $lt = $p[1]
        if ($Script:UIState[$qn].Selected -ne $lt) {
            $this.Background = $C.OptNormal
        }
    })

    return $ob
}

function Select-Option([int]$qNum, [string]$letter) {
    $st = $Script:UIState[$qNum]
    if ($null -eq $st) { return }

    $prev = $st.Selected

    # Limpiar anterior
    if ($prev) {
        $st.OptionBorders[$prev].Background       = $C.OptNormal
        $st.OptionBorders[$prev].BorderBrush      = $null
        $st.OptionBorders[$prev].BorderThickness  = [System.Windows.Thickness]::new(0)
        $st.OptionTexts[$prev].Foreground         = $C.TxtSec
    }

    # Toggle: mismo click desmarca
    if ($prev -eq $letter) {
        $st.Selected = $null
        Update-Progress
        return
    }

    # Marcar nueva
    $st.OptionBorders[$letter].Background      = $C.OptSel
    $st.OptionBorders[$letter].BorderBrush     = $C.BorderSel
    $st.OptionBorders[$letter].BorderThickness = [System.Windows.Thickness]::new(1)
    $st.OptionTexts[$letter].Foreground        = $C.TxtPri
    $st.Selected = $letter

    Update-Progress
}

# =============================================================================
# BLOQUE 12: PROGRESO
# =============================================================================

function Update-Progress {
    if ($Script:Questions.Count -eq 0) { return }
    $ans   = ($Script:UIState.Values | Where-Object { $null -ne $_.Selected }).Count
    $total = $Script:Questions.Count
    $Script:HdrProgress.Text = "$ans / $total  respondidas"
    $Script:FooterMsg.Text   = "Respondidas: $ans de $total"
}

# =============================================================================
# BLOQUE 12b: ZOOM
# =============================================================================

$Script:CurrentZoom = 1.2

function Apply-Zoom([double]$zoom) {
    $zoom = [Math]::Round([Math]::Max(0.6, [Math]::Min(2.0, $zoom)), 2)
    $Script:CurrentZoom = $zoom

    # Aplicar ScaleTransform al WrapPanel de preguntas
    $st = [System.Windows.Media.ScaleTransform]::new($zoom, $zoom)
    $Script:QPanel.LayoutTransform = $st

    # Ajustar ItemWidth segun zoom (base 370)
    $Script:QPanel.ItemWidth = [Math]::Round(370 * $zoom)

    # Sincronizar slider sin disparar evento (comparar valor)
    if ([Math]::Abs($Script:ZoomSlider.Value - $zoom) -gt 0.01) {
        $Script:ZoomSlider.Value = $zoom
    }
    $Script:ZoomLabel.Text = "$([Math]::Round($zoom * 100))%"
}

# =============================================================================
# BLOQUE 13: ACCIONES
# =============================================================================

function Action-LoadText {
    $raw = $Script:TxtQ.Text.Trim()
    if ($raw -eq '' -or $Script:TxtQ.Foreground.Color -eq $C.TxtMut.Color) {
        $Script:LblQSt.Text = "⚠ Pega el texto primero."
        $Script:LblQSt.Foreground = $C.Yellow
        return
    }
    Load-QuestionsFrom $raw
}

function Action-OpenFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Filter = "Archivos de texto (*.txt)|*.txt|Todos los archivos (*.*)|*.*"
    $dlg.Title  = "Abrir archivo de preguntas"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $raw = [System.IO.File]::ReadAllText($dlg.FileName, [System.Text.Encoding]::UTF8)
        $Script:TxtQ.Text = $raw
        $Script:TxtQ.Foreground = $C.TxtPri
        Load-QuestionsFrom $raw
    }
}

function Load-QuestionsFrom([string]$raw) {
    $list = Parse-Questions $raw
    if ($list.Count -eq 0) {
        $Script:LblQSt.Text = "⚠ No se reconocieron preguntas. Revisa el formato."
        $Script:LblQSt.Foreground = $C.Yellow
        return
    }

    $Script:Questions = $list
    $Script:UIState   = @{}
    $Script:QPanel.Children.Clear()

    foreach ($q in $Script:Questions) {
        $Script:QPanel.Children.Add((Build-QuestionCard $q)) | Out-Null
    }

    $Script:SV.Content = $Script:QPanel
    $Script:LblQSt.Text = "✓ $($list.Count) preguntas cargadas."
    $Script:LblQSt.Foreground = $C.Green
    Update-Progress
    $Script:FooterMsg.Text = "Test listo — $($list.Count) preguntas."
}

function Action-LoadKey {
    $raw = $Script:TxtKeyVisible.Text.Trim()
    if ($raw -eq '' -or $raw -eq "O pega aquí: 1.B 2.C 3.A ..." -or
        $Script:TxtKeyVisible.Foreground.Color -eq $C.TxtMut.Color) {
        $Script:LblKSt.Text = "⚠ Pega la clave en el campo primero."
        $Script:LblKSt.Foreground = $C.Yellow
        return
    }
    Load-KeyFromText $raw
    # Enmascarar campo tras cargar
    $cnt = $Script:AnswerKeys.Count
    if ($cnt -gt 0) {
        $Script:TxtKeyVisible.Text = "●●●●●●●●●●●●  ($cnt respuestas cargadas)"
        $Script:TxtKeyVisible.Foreground = $C.Green
        $Script:TxtKeyVisible.IsReadOnly = $true
    }
}

function Load-KeyFromText([string]$raw) {
    $Script:RealKeyText = $raw
    $Script:AnswerKeys  = Parse-AnswerKey $raw
    $cnt = $Script:AnswerKeys.Count
    if ($cnt -eq 0) {
        $Script:LblKSt.Text = "⚠ Formato no reconocido. Usa: 1.B 2.C ..."
        $Script:LblKSt.Foreground = $C.Yellow
    } else {
        $Script:LblKSt.Text = "✓ $cnt respuestas cargadas."
        $Script:LblKSt.Foreground = $C.Green
    }
}

function Action-OpenKeyFile {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = [System.Windows.Forms.OpenFileDialog]::new()
    $dlg.Filter = "Archivos de texto (*.txt)|*.txt|Todos los archivos (*.*)|*.*"
    $dlg.Title  = "Abrir archivo con clave de respuestas"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $raw = [System.IO.File]::ReadAllText($dlg.FileName, [System.Text.Encoding]::UTF8)
        Load-KeyFromText $raw
        $cnt = $Script:AnswerKeys.Count
        if ($cnt -gt 0) {
            $Script:TxtKeyVisible.Text = "●●●●●●●●●●●●  ($cnt respuestas cargadas)"
            $Script:TxtKeyVisible.Foreground = $C.Green
            $Script:TxtKeyVisible.IsReadOnly = $true
        }
    }
}

function Action-Reset {
    if ($Script:Questions.Count -eq 0) { return }
    foreach ($num in $Script:UIState.Keys) {
        $st = $Script:UIState[$num]
        foreach ($ltr in @($st.OptionBorders.Keys)) {
            $st.OptionBorders[$ltr].Background       = $C.OptNormal
            $st.OptionBorders[$ltr].BorderBrush      = $null
            $st.OptionBorders[$ltr].BorderThickness  = [System.Windows.Thickness]::new(0)
            $st.OptionTexts[$ltr].Foreground         = $C.TxtSec
        }
        $st.Selected = $null
        $st.Badge.Background      = $C.Accent
        $st.BadgeTxt.Foreground   = $C.TxtPri
    }
    Update-Progress
    $Script:FooterMsg.Text = "Respuestas reiniciadas."
}

function Action-ClearAll {
    $r = [System.Windows.MessageBox]::Show(
        "¿Limpiar todo? Se perderán las preguntas y respuestas.",
        "Confirmar", [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)
    if ($r -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $Script:Questions  = [System.Collections.Generic.List[PSObject]]::new()
    $Script:AnswerKeys = @{}
    $Script:UIState    = @{}

    $Script:SV.Content = Build-EmptyState
    $Script:LblQSt.Text = ""
    $Script:LblKSt.Text = ""
    $Script:HdrProgress.Text = ""
    $Script:FooterMsg.Text   = "Carga las preguntas para comenzar."

    $Script:TxtQ.Text = "Pega aquí las preguntas tipo test..."
    $Script:TxtQ.Foreground = $C.TxtMut
    $Script:TxtKeyVisible.Text = "O pega aquí: 1.B 2.C 3.A ..."
    $Script:TxtKeyVisible.Foreground = $C.TxtMut
    $Script:TxtKeyVisible.IsReadOnly = $false
    $Script:RealKeyText = ""
}

function Action-Correct {
    if ($Script:Questions.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Carga las preguntas primero.", "Sin preguntas",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }
    if ($Script:AnswerKeys.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "No hay clave cargada.`nIntroduce la clave en el panel izquierdo.",
            "Sin clave", [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $correct = 0; $wrong = 0; $blank = 0; $evaluated = 0

    foreach ($q in $Script:Questions) {
        $num  = $q.Number
        $st   = $Script:UIState[$num]
        $ans  = $Script:AnswerKeys[$num]
        $sel  = $st.Selected

        # Sin clave para esta pregunta: no evaluar, no colorear
        if (-not $ans) { continue }
        $evaluated++

        # Colorear opciones
        foreach ($ltr in @($st.OptionBorders.Keys)) {
            $ob   = $st.OptionBorders[$ltr]
            $otxt = $st.OptionTexts[$ltr]
            if ($ltr -eq $ans) {
                $ob.Background      = $C.OptCorrect
                $ob.BorderBrush     = $C.Green
                $ob.BorderThickness = [System.Windows.Thickness]::new(1)
                $otxt.Foreground    = $C.Green
            } elseif ($ltr -eq $sel -and $sel -ne $ans) {
                $ob.Background      = $C.OptWrong
                $ob.BorderBrush     = $C.Red
                $ob.BorderThickness = [System.Windows.Thickness]::new(1)
                $otxt.Foreground    = $C.Red
            } else {
                $ob.Background      = $C.OptNormal
                $ob.BorderBrush     = $null
                $ob.BorderThickness = [System.Windows.Thickness]::new(0)
                $otxt.Foreground    = $C.TxtSec
            }
        }

        # Contadores y badge
        if ($null -eq $sel) {
            $blank++
            $st.Badge.Background    = (rgb 60 55 20)
            $st.BadgeTxt.Foreground = $C.Yellow
        } elseif ($sel -eq $ans) {
            $correct++
            $st.Badge.Background    = (rgb 22 80 45)
            $st.BadgeTxt.Foreground = $C.Green
        } else {
            $wrong++
            $st.Badge.Background    = (rgb 80 22 30)
            $st.BadgeTxt.Foreground = $C.Red
        }
    }

    Show-ResultsWindow $correct $wrong $blank $evaluated
}

function Action-Export {
    if ($Script:Questions.Count -eq 0) { return }

    $lines = @()
    foreach ($q in $Script:Questions) {
        $sel = $Script:UIState[$q.Number].Selected
        $lines += "$($q.Number).$( if ($sel) { $sel } else { '__' } )"
    }

    $out = ""
    for ($i = 0; $i -lt $lines.Count; $i += 10) {
        $out += ($lines[$i..([Math]::Min($i+9,$lines.Count-1))] -join "  ") + "`n"
    }

    Show-ExportWindow $out.Trim()
}

# =============================================================================
# BLOQUE 14: VENTANA RESULTADOS
# =============================================================================

function Show-ResultsWindow([int]$correct, [int]$wrong, [int]$blank, [int]$total) {
    # Puntuacion neta: A - (E/2). Blancos no puntuan ni restan.
    # Nota sobre 10: (puntuacion_neta / total) * 10
    $netScore  = $correct - ($wrong / 2.0)
    $netScore  = [Math]::Max(0, $netScore)
    $nota10    = if ($total -gt 0) { [Math]::Round($netScore / $total * 10, 2) } else { 0 }
    $pct       = if ($total -gt 0) { [Math]::Round($netScore / $total * 100, 1) } else { 0 }
    $color     = if ($pct -ge 70) { $C.Green } elseif ($pct -ge 50) { $C.Yellow } else { $C.Red }
    $netRound  = [Math]::Round($netScore, 2)
    $penalty   = [Math]::Round($wrong / 2.0, 1)

    $w = [System.Windows.Window]::new()
    $w.Title      = "Resultado del test"
    $w.Width      = 480
    $w.Height     = 400
    $w.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $w.Background = $C.Surface
    $w.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $w.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner

    $sp = New-VStack
    $sp.Margin = [System.Windows.Thickness]::new(32,24,32,24)

    # Titulo
    $t1 = New-TB "Resultado del test" 20 $C.TxtPri $true
    $t1.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $t1.Margin = [System.Windows.Thickness]::new(0,0,0,10)

    # Puntuacion grande: pct% y nota/10
    $scoreRow = New-HStack
    $scoreRow.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $scoreRow.Margin = [System.Windows.Thickness]::new(0,0,0,4)

    $scoreTB = New-TB "$pct%" 50 $color $true
    $scoreTB.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom

    $notaTB = New-TB "  ($nota10 / 10)" 20 $C.TxtSec $true
    $notaTB.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
    $notaTB.Margin = [System.Windows.Thickness]::new(0,0,0,6)

    $scoreRow.Children.Add($scoreTB) | Out-Null
    $scoreRow.Children.Add($notaTB)  | Out-Null

    # Formula
    $formula = New-TB "A - (E÷2) = $correct - ($wrong÷2) = $netRound pts / $total preguntas" 11 $C.TxtMut
    $formula.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $formula.Margin = [System.Windows.Thickness]::new(0,0,0,18)

    # 4 celdas de desglose
    $g4 = [System.Windows.Controls.Grid]::new()
    Add-Col $g4 '*'; Add-Col $g4 '*'; Add-Col $g4 '*'; Add-Col $g4 '*'

    $cells = @(
        @{ T="✓ Correctas";     V="$correct";   Cl=$C.Green  }
        @{ T="✗ Incorrectas";   V="$wrong";      Cl=$C.Red    }
        @{ T="— Sin responder"; V="$blank";      Cl=$C.Yellow }
        @{ T="Penalización";    V="-$penalty";   Cl=$C.Red    }
    )
    for ($i = 0; $i -lt 4; $i++) {
        $cell = New-VBorder $C.Card 8
        $cell.Padding = [System.Windows.Thickness]::new(6,10,6,10)
        $lpad = if ($i -eq 0) { 0 } else { 4 }
        $rpad = if ($i -eq 3) { 0 } else { 4 }
        $cell.Margin = [System.Windows.Thickness]::new($lpad,0,$rpad,0)
        $cv = New-VStack
        $n  = New-TB $cells[$i].V 22 $cells[$i].Cl $true
        $n.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $l  = New-TB $cells[$i].T 9 $C.TxtMut
        $l.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $l.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $cv.Children.Add($n) | Out-Null
        $cv.Children.Add($l) | Out-Null
        $cell.Child = $cv
        [System.Windows.Controls.Grid]::SetColumn($cell, $i)
        $g4.Children.Add($cell) | Out-Null
    }
    $g4.Margin = [System.Windows.Thickness]::new(0,0,0,20)

    $btnC = New-Btn "Cerrar" $C.Accent 120
    $btnC.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $btnC.Add_Click({ $w.Close() })

    foreach ($el in @($t1,$scoreRow,$formula,$g4,$btnC)) {
        $sp.Children.Add($el) | Out-Null
    }

    $w.Content = $sp
    $w.ShowDialog() | Out-Null
}

# =============================================================================
# BLOQUE 15: VENTANA EXPORTAR
# =============================================================================

function Show-ExportWindow([string]$out) {
    $w = [System.Windows.Window]::new()
    $w.Title  = "Exportar respuestas"
    $w.Width  = 560
    $w.Height = 340
    $w.Background = $C.Surface
    $w.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
    $w.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner

    $g = [System.Windows.Controls.Grid]::new()
    Add-Row $g 50; Add-Row $g '*'; Add-Row $g 56

    $hb = New-VBorder $C.Card
    $hb.Padding = [System.Windows.Thickness]::new(20,0,20,0)
    $ht = New-TB "Respuestas exportadas" 14 $C.TxtPri $true
    $ht.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $hb.Child = $ht

    $tb = [System.Windows.Controls.TextBox]::new()
    $tb.Text = $out
    $tb.IsReadOnly = $true
    $tb.AcceptsReturn = $true
    $tb.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $tb.Background   = $C.Bg
    $tb.Foreground   = $C.TxtPri
    $tb.CaretBrush   = $C.TxtPri
    $tb.BorderThickness = [System.Windows.Thickness]::new(0)
    $tb.Padding      = [System.Windows.Thickness]::new(20,14,20,14)
    $tb.FontFamily   = [System.Windows.Media.FontFamily]::new("Consolas")
    $tb.FontSize     = 14
    $tb.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto

    $fb = New-VBorder $C.Card
    $fb.Padding = [System.Windows.Thickness]::new(16,0,16,0)
    $fr = New-HStack
    $fr.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $fr.VerticalAlignment   = [System.Windows.VerticalAlignment]::Center

    $btnCopy = New-Btn "📋  Copiar" $C.Accent
    $btnCopy.Add_Click({
        [System.Windows.Clipboard]::SetText($out)
        $btnCopy.Content = "✓  Copiado"
    })
    $btnClose = New-Btn "Cerrar" (rgb 55 55 90)
    $btnClose.Margin = [System.Windows.Thickness]::new(8,0,0,0)
    $btnClose.Add_Click({ $w.Close() })

    $fr.Children.Add($btnCopy)  | Out-Null
    $fr.Children.Add($btnClose) | Out-Null
    $fb.Child = $fr

    GPos $hb 0 0; GPos $tb 1 0; GPos $fb 2 0
    $g.Children.Add($hb) | Out-Null
    $g.Children.Add($tb) | Out-Null
    $g.Children.Add($fb) | Out-Null

    $w.Content = $g
    $w.ShowDialog() | Out-Null
}

# =============================================================================
# BLOQUE 16: ARRANQUE
# =============================================================================

$Win = New-MainWindow
$Win.Add_Loaded({ Apply-Zoom 1.2 })
[void]$Win.ShowDialog()