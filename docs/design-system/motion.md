# Motion

`FwMotion` provides the duration/curve/spring scales:

- Speeds: `FwMotionSpeed.xs` (80ms) … `.xl` (480ms); resolve with
  `theme.motion.durationFor(context, FwMotionSpeed.medium)`.
- Emphasized easings (standard + emphasized) and `FwSpring` configs that
  convert to Flutter `SpringDescription`.

## Rules

- Every animation reads `MediaQuery.disableAnimations`: under reduced
  motion, speeds collapse to zero (instant transitions) — tested.
- Durations come from the scale; never hard-code millisecond values in
  components.
- Haptics pair with motion for confirmations (`FwHaptics`), and are
  skipped under accessible navigation or when the theme disables them.
- Skeleton shimmer and loading spinners must also honor reduced motion
  (no perpetual animation for users who opted out).
