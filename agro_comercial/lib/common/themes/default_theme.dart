import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Tema do app: as telas herdam daqui botões, campos, cards, diálogos, barras
// e as transições entre telas.

const _radius = 14.0;
final _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(_radius),
);

const _colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primarySoft,
  onPrimaryContainer: AppColors.primaryDark,
  secondary: AppColors.harvest,
  onSecondary: AppColors.onHarvest,
  secondaryContainer: AppColors.harvestSoft,
  onSecondaryContainer: AppColors.onHarvest,
  tertiary: AppColors.earth,
  onTertiary: Colors.white,
  tertiaryContainer: AppColors.earthSoft,
  onTertiaryContainer: AppColors.earth,
  error: AppColors.danger,
  onError: Colors.white,
  errorContainer: AppColors.dangerSoft,
  onErrorContainer: AppColors.danger,
  surface: AppColors.surface,
  onSurface: AppColors.ink,
  onSurfaceVariant: AppColors.inkMuted,
  surfaceContainerLowest: AppColors.surface,
  surfaceContainerLow: AppColors.background,
  surfaceContainer: AppColors.surfaceMuted,
  surfaceContainerHigh: AppColors.surfaceMuted,
  surfaceContainerHighest: AppColors.border,
  outline: AppColors.border,
  outlineVariant: AppColors.border,
  shadow: AppColors.primaryDark,
  surfaceTint: Colors.transparent,
);

OutlineInputBorder _inputBorder(Color color, [double width = 1.2]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: width),
    );

final defaultTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _colorScheme,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: AppColors.background,
  splashFactory: InkSparkle.splashFactory,
  visualDensity: VisualDensity.standard,

  // Transição suave entre telas (deslizar + esmaecer)
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    },
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: Colors.white,
    ),
  ),

  cardTheme: CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    // Sombra suave puxada para o verde (vale também para cards com
    // elevation definida na tela)
    shadowColor: AppColors.primaryDark.withValues(alpha: 0.18),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(
      color: AppColors.inkMuted,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(color: AppColors.inkMuted.withValues(alpha: 0.6)),
    helperStyle: const TextStyle(color: AppColors.inkMuted),
    errorStyle: const TextStyle(color: AppColors.danger),
    prefixIconColor: AppColors.inkMuted,
    suffixIconColor: AppColors.inkMuted,
    border: _inputBorder(AppColors.border),
    enabledBorder: _inputBorder(AppColors.border),
    disabledBorder: _inputBorder(AppColors.surfaceMuted),
    focusedBorder: _inputBorder(AppColors.primary, 1.8),
    errorBorder: _inputBorder(AppColors.danger),
    focusedErrorBorder: _inputBorder(AppColors.danger, 1.8),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(64, 52),
      shape: _shape,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(64, 50),
      shape: _shape,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(64, 50),
      side: const BorderSide(color: AppColors.border, width: 1.4),
      shape: _shape,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: _shape,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(shape: _shape),
  ),

  // Botão (+) em amarelo safra: a ação principal de cada tela
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.harvest,
    foregroundColor: AppColors.onHarvest,
    elevation: 3,
    highlightElevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    extendedTextStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primarySoft,
    elevation: 0,
    height: 70,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.inkMuted,
        size: 24,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w500,
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.inkMuted,
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.inkMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),

  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
    ),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    contentTextStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 1.45,
      color: AppColors.inkMuted,
    ),
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: AppColors.border,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.ink,
    elevation: 4,
    insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    contentTextStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: AppColors.primary,
    textColor: AppColors.ink,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    subtitleTextStyle: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: AppColors.inkMuted,
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primarySoft,
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    labelStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  ),

  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.white
          : AppColors.inkMuted,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.surfaceMuted,
    ),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    circularTrackColor: AppColors.primarySoft,
    linearTrackColor: AppColors.primarySoft,
    refreshBackgroundColor: AppColors.surface,
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicatorColor: AppColors.harvest,
    dividerColor: Colors.transparent,
    labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
  ),

  datePickerTheme: DatePickerThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: AppColors.primary,
    headerForegroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),

  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
);
