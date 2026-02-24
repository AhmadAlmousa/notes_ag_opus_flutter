## Quick Reference 

| Topic | Section |
|-------|------|
| setState, state loss, keys | `State_Traps` |
| build method, context, GlobalKey | `Widget_Traps` |
| FutureBuilder, dispose, mounted | `Async_Traps` |
| Context after pop, deep linking | `Navigation Traps` |
| const, rebuilds, performance | `Performance_Traps` |
| Platform channels, null safety | `Platform_Channel_Traps` |

## Critical Rules

- `setState` after dispose — check `mounted` before calling, crashes otherwise
- Key missing on list items — reordering breaks state, always use keys
- FutureBuilder rebuilds on parent rebuild — triggers future again, cache the Future
- BuildContext after async gap — context may be invalid, check `mounted` first
- `const` constructor — prevents rebuilds, use for static widgets
- `StatefulWidget` recreated — key change or parent rebuild creates new state
- GlobalKey expensive — don't use just to access state, pass callbacks instead
- `dispose` incomplete — cancel timers, subscriptions, controllers
- Navigator.pop with result — returns Future, don't ignore errors
- ScrollController not disposed — memory leak
- Image caching — use `cached_network_image`, default doesn't persist
- PlatformException not caught — platform channel calls can throw

---

## Sections

# Section: State_Traps

- `setState` after dispose — crashes, check `if (mounted)` first
- State lost on parent rebuild — use key to preserve, or lift state up
- Key type matters — `ValueKey`, `ObjectKey`, `UniqueKey` have different equality
- Missing key in list — Flutter can't track which item changed, state mismatches
- `const` widget with state — state preserved even if you expect reset
- initState async — can't await, use `Future.microtask` or `WidgetsBinding.addPostFrameCallback`
- State in build method — recreated every build, move to field
- Late init in initState — widget.property safe, context is not

# Section: Widget_Traps

- Context in initState — `context` not fully available, defer to `didChangeDependencies`
- BuildContext after async — may be unmounted, check `mounted` first
- GlobalKey across routes — can cause "already has a parent" error
- Scaffold.of(context) — context must be below Scaffold, not same level
- Theme.of(context) — same issue, use Builder widget to get correct context
- Widget identity — same runtime type + key = same widget, state preserved
- SizedBox vs Container — SizedBox is const-friendly, prefer for fixed sizes
- Expensive build method — move computation to initState or FutureBuilder

# Section: Async_Traps

- FutureBuilder triggers on every rebuild — cache Future in initState or field
- StreamBuilder — same issue, cache stream or use BehaviorSubject for replay
- `mounted` check — always before setState after await
- Dispose before async completes — subscription/timer fires on disposed widget
- CancelToken in dispose — cancel ongoing HTTP requests
- Error handling in FutureBuilder — provide builder for error state
- RefreshIndicator with FutureBuilder — tricky combo, manage state separately
- Timer.periodic — must cancel in dispose, or keeps firing
- AnimationController — must dispose, vsync requires TickerProviderStateMixin


# Section: Navigation_Traps

- Context after pop — Navigator.pop may invalidate context, don't use after
- `pushReplacement` — previous route disposed, can't go back
- Route arguments type safety — use generic `Navigator.push<T>` and cast result
- Deep link parsing — check null, validate format before navigating
- Named routes with arguments — pass via `RouteSettings.arguments`, retrieve with `ModalRoute.of(context)`
- Multiple navigation stacks — Navigator.push keeps old route in memory
- Back button handling — use `WillPopScope` (deprecated) or `PopScope` (3.16+)
- Route observer — must register with Navigator to receive callbacks


# Section: Performance_Traps

- Missing `const` — non-const widgets rebuild children even if unchanged
- ListView without builder — loads all items into memory, use `.builder`
- Large list itemExtent — providing fixed height enables optimizations
- Image not cached — use `cached_network_image` package
- setState scope — rebuilds entire widget, extract child widgets
- RepaintBoundary — isolates repaint region, use for animations
- ValueListenableBuilder — better than setState for single value changes
- AutomaticKeepAliveClientMixin — preserves TabBarView/PageView state but uses memory
- Opacity widget expensive — prefer `FadeTransition` or `AnimatedOpacity`


# Section: Platform_Channel_Traps

- PlatformException — always wrap channel calls in try-catch
- Null from platform — platform returns null, Dart expects non-null, crash
- Main thread only — UI updates from platform must be on main thread
- Binary messenger — raw bytes need codec handling
- Method channel naming — use reverse domain, conflicts with other plugins
- Missing implementation — iOS/Android not implemented, crashes at runtime
- Codec mismatch — JSON encode/decode must match platform expectations
- Background execution — platform channels don't work when app killed
