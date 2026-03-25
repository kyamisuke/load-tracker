import SwiftUI

// ============================================================
// あしあと — DesignTokens.swift
// Dark Theme / Amber Accent
// ============================================================

// MARK: - Primitive Colors

extension Color {
    enum Primitive {

        // Amber
        /// メインアクセント。ボタン・記録中バッジ・軌跡グラデ終端
        static let amber        = Color(hex: "#F5A623")
        /// サブアクセント。グラデーション始端・アイコン背景
        static let amberDim     = Color(hex: "#C47D0E")
        /// 薄いアンバー。タグ背景・グロー
        static let amberGlow    = Color(hex: "#F5A623").opacity(0.18)
        static let amberGlow2   = Color(hex: "#F5A623").opacity(0.32)

        // Background
        /// アプリ最背面。純黒に近いが赤みをわずかに含む
        static let void         = Color(hex: "#0A0A0B")
        /// セカンダリ背景。カード・シート下地
        static let surface      = Color(hex: "#141416")
        /// カード背景
        static let card         = Color(hex: "#1C1C1F")
        /// カードホバー（押下フィードバック）
        static let cardActive   = Color(hex: "#222226")

        // Text
        /// プライマリテキスト。見出し・本文
        static let snow         = Color(hex: "#F0EDE8")
        /// セカンダリテキスト。サブラベル・補足
        static let ash          = Color(hex: "#8A8680")
        /// 区切り線・無効状態
        static let dust         = Color(hex: "#3A3A3E")

        // Semantic
        /// 警告・一部記録あり・削除
        static let ember        = Color(hex: "#FF6B4A")
        /// 完了・完全記録
        static let mint         = Color(hex: "#4AE0A0")
    }
}

// MARK: - Hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double((int      ) & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


// MARK: - Semantic Colors
// コンポーネントが直接参照するレイヤー。
// ここを変えるだけで全体に反映される。

extension Color {
    enum App {

        // Button
        static let buttonPrimaryBg       = Primitive.amber
        static let buttonPrimaryFg       = Color(hex: "#1A0F00")
        static let buttonSecondaryBorder = Primitive.amber.opacity(0.5)
        static let buttonSecondaryFg     = Primitive.amber

        // Recording Badge
        static let recBadgeBg            = Primitive.card
        static let recBadgeBorder        = Primitive.amber.opacity(0.35)
        static let recDot                = Primitive.amber
        static let recLabel              = Primitive.amber
        static let recDistance           = Primitive.ash

        // History Card
        static let cardBg                = Primitive.card
        static let cardBorder            = Color.white.opacity(0.05)
        static let cardAccentActive      = Primitive.amber       // 記録中
        static let cardAccentInterrupted = Primitive.ember       // 一部記録あり
        static let cardAccentNormal      = Primitive.dust        // 完了

        // Tags
        static let tagStayBg             = Primitive.amber.opacity(0.10)
        static let tagStayFg             = Color(hex: "#F7C76A")
        static let tagStayBorder         = Primitive.amber.opacity(0.20)

        static let tagWarnBg             = Primitive.ember.opacity(0.10)
        static let tagWarnFg             = Primitive.ember
        static let tagWarnBorder         = Primitive.ember.opacity(0.20)

        static let tagOkBg               = Primitive.mint.opacity(0.10)
        static let tagOkFg               = Primitive.mint
        static let tagOkBorder           = Primitive.mint.opacity(0.20)

        // Map Route
        static let routeStart            = Primitive.amberDim.opacity(0.5)
        static let routeEnd              = Primitive.amber

        // Text
        static let textPrimary           = Primitive.snow
        static let textSecondary         = Primitive.ash
        static let textFaint             = Primitive.dust

        // Background
        static let bgPrimary             = Primitive.void
        static let bgSurface             = Primitive.surface
        static let bgCard                = Primitive.card
    }
}


// MARK: - Typography

enum AppFont {
    /// 大見出し・アプリ名「あしあと」・ボタンラベル（欧文）
    static func display(_ size: CGFloat) -> Font {
        .custom("Nunito-ExtraBold", size: size)
    }

    /// セクションタイトル・バッジ・数値強調（欧文）
    static func heading(_ size: CGFloat) -> Font {
        .custom("Nunito-Bold", size: size)
    }

    /// 本文・機能説明（日本語メイン）
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("NotoSansJP-Regular", size: size).weight(weight)
    }

    /// システムフォールバック（カスタムフォント未導入時）
    static func system(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Type Scale

extension AppFont {
    enum Size {
        static let micro:   CGFloat = 10  // タグ・ステータスチップ
        static let caption: CGFloat = 12  // サブラベル・補足
        static let body:    CGFloat = 13  // 本文・機能説明
        static let labelMD: CGFloat = 14  // ボタンラベル
        static let labelLG: CGFloat = 16  // ナビゲーションタイトル
        static let titleMD: CGFloat = 18  // カード内数値・強調
        static let titleLG: CGFloat = 22  // セクション大見出し
        static let titleXL: CGFloat = 28  // 画面タイトル
        static let display: CGFloat = 36  // アプリ名・オンボーディング
    }
}


// MARK: - Spacing

enum AppSpacing {
    static let xxs: CGFloat =  4   // アイコン↔ラベル
    static let xs:  CGFloat =  8   // タグ内パディング・アイテム間
    static let sm:  CGFloat = 12   // カード内余白
    static let md:  CGFloat = 16   // 画面水平マージン・セクション間
    static let lg:  CGFloat = 24   // カード間・グループ間
    static let xl:  CGFloat = 32   // セクション間（大）
    static let xxl: CGFloat = 48   // オンボーディング余白
}


// MARK: - Corner Radius

enum AppRadius {
    static let pill:    CGFloat = 999  // タグ・バッジ・Pill型ボタン・RecordingBadge
    static let button:  CGFloat =  18  // メインボタン・サブボタン
    static let card:    CGFloat =  22  // 履歴カード
    static let icon:    CGFloat =  14  // フィーチャーアイコン背景
    static let miniMap: CGFloat =  12  // カード内地図サムネイル
}


// MARK: - Shadow

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension AppShadow {
    /// 「記録を始める」ボタン発光
    static let buttonPrimary = AppShadow(
        color: Color.Primitive.amber.opacity(0.40),
        radius: 24, x: 0, y: 4
    )
    /// カード浮き上がり
    static let card = AppShadow(
        color: .black.opacity(0.40),
        radius: 20, x: 0, y: 8
    )
    /// 現在地ドット
    static let locationDot = AppShadow(
        color: Color.Primitive.amber.opacity(0.50),
        radius: 14, x: 0, y: 0
    )
}


// MARK: - Animation

enum AppAnimation {
    /// 記録中ドットのパルス（RecordingBadge）
    static let pulse = Animation
        .easeInOut(duration: 1.4)
        .repeatForever(autoreverses: true)

    /// 画面遷移・モーダル
    static let transition = Animation
        .spring(response: 0.4, dampingFraction: 0.75)

    /// ボタン押下フィードバック（scale + opacity）
    static let tap = Animation.easeOut(duration: 0.12)
}


// MARK: - Component Tokens
// 各コンポーネントファイルはここだけを参照する。

enum Token {

    enum Button {
        static let primaryBg       = Color.App.buttonPrimaryBg
        static let primaryFg       = Color.App.buttonPrimaryFg
        static let primaryShadow   = AppShadow.buttonPrimary
        static let secondaryBorder = Color.App.buttonSecondaryBorder
        static let secondaryFg     = Color.App.buttonSecondaryFg
        static let height: CGFloat = 52
        static let radius          = AppRadius.button
        static let font            = AppFont.heading(AppFont.Size.labelMD)
    }

    enum RecordingBadge {
        static let bg        = Color.App.recBadgeBg
        static let border    = Color.App.recBadgeBorder
        static let dot       = Color.App.recDot
        static let label     = Color.App.recLabel
        static let dist      = Color.App.recDistance
        static let animation = AppAnimation.pulse
    }

    enum HistoryCard {
        static let bg                = Color.App.cardBg
        static let border            = Color.App.cardBorder
        static let radius            = AppRadius.card
        static let accentActive      = Color.App.cardAccentActive
        static let accentInterrupted = Color.App.cardAccentInterrupted
        static let accentNormal      = Color.App.cardAccentNormal
        static let accentWidth: CGFloat = 3.5
        static let distFont          = AppFont.heading(AppFont.Size.titleMD)
        static let miniMapHeight: CGFloat = 56
        static let miniMapRadius     = AppRadius.miniMap
    }

    enum Tag {
        static let radius = AppRadius.pill
        enum Stay {
            static let bg     = Color.App.tagStayBg
            static let fg     = Color.App.tagStayFg
            static let border = Color.App.tagStayBorder
        }
        enum Warn {
            static let bg     = Color.App.tagWarnBg
            static let fg     = Color.App.tagWarnFg
            static let border = Color.App.tagWarnBorder
        }
        enum Ok {
            static let bg     = Color.App.tagOkBg
            static let fg     = Color.App.tagOkFg
            static let border = Color.App.tagOkBorder
        }
    }

    enum MapRoute {
        static let start      = Color.App.routeStart
        static let end        = Color.App.routeEnd
        static let lineWidth: CGFloat = 4
    }
}
