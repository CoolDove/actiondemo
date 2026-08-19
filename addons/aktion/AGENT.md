# AGENTS.md — Aktion 插件

Godot 编辑器插件，提供 AnimationPlayer 的动画 track 批处理工具（复制 / 覆盖 / 删除）。GDScript 实现，`@tool` 脚本，编辑器停靠面板形态。

## 文件布局

| 路径 | 职责 |
|------|------|
| `plugin.cfg` | 插件声明。`script=aktion_plugin.gd` |
| `aktion_plugin.gd` | 插件入口（`EditorPlugin`）：实例化面板、停靠、`_handles`/`_edit` 绑定选中的 AnimationPlayer |
| `aktion_anim_editor.gd` | 主面板逻辑（复制/覆盖/删除、撤销、动画列表刷新） |
| `aktion_anim_editor.tscn` | 主面板 UI：PlayerLabel + TabContainer(复制/删除) |
| `animation_track_filter.gd` | 可复用组件 `AnimationTrackFilter`：路径过滤输入 + 匹配 track 列表 |
| `animation_track_filter.tscn` | 组件 UI：FilterLabel + FilterEdit + CheckBox_Regex/CheckBox_CaseSensitive + CountLabel + ScrollContainer/TrackList |
| `aktion_animation.gd` | `class_name AktionAnimation extends Animation`，自定义动画资源类型占位（暂无逻辑） |

每个 `.gd` 都有同名的 `.gd.uid` 伴生文件（Godot 生成，勿删）。`.tscn` 通过文件头 `uid="uid://..."` 标识，无独立 `.uid` 文件。

## 架构与数据流

### 插件生命周期
1. `aktion_plugin.gd::_enter_tree` → `preload(...tscn).instantiate()` → `_anim_editor.setup(self)` → `add_control_to_dock(DOCK_SLOT_LEFT_BL, ...)`。
2. 用户选中 AnimationPlayer → `_edit(object)` → `_anim_editor.set_target_player(object)`。
3. `_exit_tree` 卸载面板并 `queue_free`。

注意：`setup()` 在 `add_control_to_dock` 之前调用，此时节点尚未进入场景树，`@onready` 变量为 null。所以 `setup()` 里只能用 `%Node` 直接连信号（get_node 立即可用），不能碰 `@onready` 变量；刷新一律走脏标记延迟到 `_process`。

### 主面板 `aktion_anim_editor.gd`
- 根节点 `VBoxContainer`，`@tool`。持有 `editor_plugin` 和 `target_player`。
- 结构：`PlayerLabel` → `Tabs`(TabContainer，`size_flags_vertical=3`)。状态反馈（选中提示/操作结果/错误）直接写 `PlayerLabel`，下次 `_refresh` 再被「目标: X」覆盖。
  - `CopyTab`：`SourceAnimation`(SourceLabel/SourceOption/SourceFilter) + `DestinationAnimation`(TargetLabel/TargetOption) + `Actions`(CopyButton/OverwriteButton)。
  - `DeleteTab`：`DeleteAnimation`(DeleteTargetLabel/DeleteTargetOption/DeleteFilter) + `DeleteActions`(DeleteButton)。
- 两个 tab 的中文标题在 `_ready()` 里用 `tabs.set_tab_title(0/1, ...)` 运行时设置（原因见「坑」）。

### 可复用组件 `AnimationTrackFilter`
- `class_name AnimationTrackFilter extends VBoxContainer`。
- 对外接口：`set_animation(anim)`（绑定要过滤的动画）、`get_filter() -> String`（去空白后的过滤串）、`get_regex() -> bool`、`get_case_sensitive() -> bool`、`static matches_path(path, filter, regex=false, case_sensitive=false) -> bool`（纯函数，匹配逻辑唯一出处）。
- 匹配语义：`filter` 为空 = 匹配全部。非 regex 模式 = 对节点路径（`path` 去掉 `:property` 后缀）做前缀匹配（`node == filter` 或 `node.begins_with(filter + '/')`）。regex 模式 = 用 `RegEx.search` 对完整 `str(path)` 匹配；`case_sensitive=false` 时在 pattern 前加 PCRE 内联标志 `(?i)`。regex 无效时 `matches_path` 返回 false。
- 开关联动：`CheckBox_Regex` 打开时自动把 `CheckBox_CaseSensitive` 置 false；case-sensitive 只在 regex 模式下有意义，regex 关闭时该复选框 `disabled`。两个复选框 toggled 都会 `_mark_dirty()` 触发重刷。
- 内部节点（`FilterEdit`/`CheckBox_Regex`/`CheckBox_CaseSensitive`/`TrackList`/`CountLabel`）都设 `unique_name_in_owner`，脚本里用 `%FilterEdit`/`%CheckBox_Regex`/`%CheckBox_CaseSensitive`/`%TrackList`/`%CountLabel` 访问。虽然本组件在同场景被实例化两次（SourceFilter / DeleteFilter），但 `%` 在子场景自身脚本内按实例作用域解析，两个实例互不冲突；只有从父场景用 `%` 访问子场景内部节点才会歧义。父场景只通过 `%SourceFilter`/`%DeleteFilter` 拿到实例根，再调用 `get_filter()` 等方法，不直接触碰内部节点。
- 列表动态生成 `Label`（无 owner，不会写入 .tscn），每次 `_refresh` 先 `_clear_list()` 再重建。

### 核心功能
- **复制 / 覆盖**（`_do_copy(overwrite)`）：源动画 = `source_option`，目标动画 = `target_option`，过滤参数来自 `source_filter.get_filter()/get_regex()/get_case_sensitive()`。覆盖模式下先把目标动画中与源 track 同路径（同名）的 track 删掉再复制。
- **删除**（`_on_delete_pressed`）：目标动画 = `delete_target_option`，过滤参数来自 `delete_filter.get_filter()/get_regex()/get_case_sensitive()`，反向遍历删除匹配 track（避免索引偏移）。
- **撤销**：操作前对目标动画做整份快照 `_snapshot_animation`（`Animation.new()` + 逐个 `copy_track`），`add_undo_method(_restore_animation, target, backup)` 通过清空 + 重拷还原，保证 track 顺序与内容都恢复。do 方法通过 `undo_redo.add_do_method` 传参（`filter`/`regex`/`case_sensitive`/`overwrite` 等可序列化值），重做时重新计算匹配。
- `PlayerLabel` 用 `_last_copied` / `_last_deleted` 记录最近一次数量；操作后 `mark_scene_as_unsaved()` + `_refresh_animation_editor()`（`set_current_animation('')` 再设回，刷新动画编辑器显示）。

## 关键约定与模式

### 脏标记 + `_process` 刷新
所有涉及 `@onready` 节点或列表重建的刷新都不直接调用，而是 `_mark_dirty()` 置位，在 `_process` 里消费一次并复位。好处：避免 ready 前刷新（null 崩溃）、多次标记只刷一次。主面板与 filter 组件都遵循此模式。

### 撤销用整份快照，而非逐条逆操作
复制/覆盖/删除都可能改 track 顺序与内容，用「快照备份 + 清空重放」最简单可靠；不要在 do 方法里依赖 UI 状态，一切匹配都通过 `AnimationTrackFilter.matches_path` 纯函数重算。

### 节点绑定默认用 Unique Name（`%`）
脚本要访问的节点一律勾选 `unique_name_in_owner`，GDScript 里用 `%NodeName` 访问，不用 `$` 相对路径。好处：节点改名/改层级/重挂父节点时引用不丢失。可复用子场景（如 `AnimationTrackFilter`）的内部节点在自身脚本里用 `%` 按实例作用域解析，多实例互不冲突；父场景只通过 `%InstanceRoot` 拿实例根。

## 坑（务必记住）

1. **`.tscn` 的 `parent` 是从场景根节点算起的完整 NodePath**，不是相对父节点名。节点在 `Tabs` 下的 `CopyTab` 里，就要写 `parent="Tabs/CopyTab"`、`parent="Tabs/CopyTab/SourceAnimation"`，写 `parent="CopyTab"` 会「Parent path has vanished」导致层级错乱。
2. **节点名 / parent 路径里不能有中文**。`.tscn` 文本解析器对 `name=`/`parent=` 用 ASCII/Latin-1，中文字符会报 `Unicode parsing error` 并让整条父路径失效、脚本变 placeholder。中文只能出现在 `text` 等属性值里，或运行时用 `set_tab_title` 之类的代码设置。
3. `unique_name_in_owner`（`%` 访问）+ `unique_id` 是 Godot 4.7 场景格式；手动编辑 `.tscn` 时新节点要分配不与同场景冲突的 `unique_id`。
4. 实例化子场景的节点写法：`[node name="X" parent="..." unique_id=N instance=ExtResource("id")]`，根节点名会被 `name=` 覆盖。
5. 静态匹配逻辑只有 `AnimationTrackFilter.matches_path` 一份，新增「按 path 过滤」的功能要复用它，不要另写 `_track_matches` 之类的重复实现。

## 代码风格
- 只改最小文件集；任务过大先与用户讨论拆分。
- 不用 `:=` 类型推断，写 `var foo = bar()`。已有 `:=` 视为有意为之，勿改。
- GDScript 只在 `@tool` 下运行编辑器逻辑；不加注释除非被要求。
