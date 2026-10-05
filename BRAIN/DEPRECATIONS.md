# Deprecated → use instead

Extracted from the official engine reference (`Roblox/creator-docs`, `deprecation_message` fields), 2026-09-25.
Only APIs that agents commonly reach for are listed.

`check.ps1` already fails on deprecated **globals and members** it knows about (`wait`, `spawn`, `delay`,
`Humanoid:LoadAnimation`, `Player:LoadCharacter`...) and on members the type definitions leave out, like `BasePart.Velocity`. It does
**not** flag `Instance.new("<DeprecatedClass>")`, or deprecations newer than the pinned type definitions
(the `PhysicsService` class is deprecated, but its collision-group methods are only marked "superseded" in the
reference, so the linter never flags them). Watch those rows.

## Scheduling

| Don't | Use |
| --- | --- |
| `wait`, `spawn`, `delay` | `task.wait`, `task.spawn`, `task.delay` (and `task.defer`, `task.cancel`) |

## Physics

| Don't | Use |
| --- | --- |
| `BodyVelocity` | `LinearVelocity` |
| `BodyAngularVelocity` | `AngularVelocity` |
| `BodyPosition` | `AlignPosition` |
| `BodyGyro` | `AlignOrientation` |
| `BodyForce`, `BodyThrust` | `VectorForce` |
| `RocketPropulsion` | `LineForce` |
| `BasePart.Velocity` / `RotVelocity` | `AssemblyLinearVelocity` / `AssemblyAngularVelocity` |
| `BasePart.Friction` / `Elasticity` / `SpecificGravity` | `BasePart.CustomPhysicalProperties` |
| `Workspace:FindPartOnRay*` | `WorldRoot:Raycast` + `RaycastParams` |
| `Workspace:FindPartsInRegion3*`, `IsRegion3Empty*` | `WorldRoot:GetPartBoundsInBox` + `OverlapParams` |
| `PhysicsService:RegisterCollisionGroup` and all other `PhysicsService` collision-group methods | `WorldRoot:RegisterCollisionGroup`, `CollisionGroupSetCollidable`, etc. (the whole service is deprecated) |
| `PhysicsService:SetPartCollisionGroup` | set `BasePart.CollisionGroup` (a string) |
| `MakeJoints` / `BreakJoints`, `Glue`, `Rotate`, `RotateP`, `RotateV` | `WeldConstraint`, `HingeConstraint`; break joints by destroying them |
| `Model:GetModelSize` | `Model:GetExtentsSize` |

## Characters and avatars

| Don't | Use |
| --- | --- |
| `Humanoid:LoadAnimation` | `Animator:LoadAnimation` |
| `PoseEasingStyle.Cubic` | `PoseEasingStyle.CubicV2` (`Cubic`'s directions come out reversed between editor and game) |
| `Player:LoadCharacter` | `Player:LoadCharacterAsync` |
| `Player:LoadCharacterWithHumanoidDescription` | `...Async` version |
| `Humanoid:ApplyDescription` / `ApplyDescriptionReset` | `ApplyDescriptionAsync` / `ApplyDescriptionResetAsync` |
| `Humanoid:PlayEmote` | `Humanoid:PlayEmoteAsync` |
| `Players:GetHumanoidDescriptionFromUserId` / `FromOutfitId` | `...Async` versions |
| `Players:CreateHumanoidModelFromUserId` / `FromDescription` | `...Async` versions |
| `Humanoid.Torso`, `LeftLeg`, `RightLeg` | R6-only; find parts on the character model |
| `Hat` | `Accessory` |
| `Skin` | `BodyColors` |

## Players, groups, friends

| Don't | Use |
| --- | --- |
| `Player:IsInGroup` | `Player:IsInGroupAsync` |
| `Player:GetRankInGroup(Async)` / `GetRoleInGroup(Async)` | `GroupService:GetRolesInGroupAsync` (returns all roles) |
| `Player:IsFriendsWith` | `Player:IsFriendsWithAsync` |
| `Player:GetFriendsOnline` | `Player:GetFriendsOnlineAsync` |
| `Player.MembershipType` | `Player.HasRobloxSubscription` |
| `Players.NumPlayers` | `#Players:GetPlayers()` |

## Marketplace and badges

| Don't | Use |
| --- | --- |
| `MarketplaceService:GetProductInfo` | `GetProductInfoAsync` |
| `MarketplaceService:PlayerOwnsAsset` / `PlayerOwnsBundle` | `PlayerOwnsAssetAsync` / `PlayerOwnsBundleAsync` |
| `MarketplaceService:PromptPremiumPurchase` | `PromptRobloxSubscriptionPurchase` |
| `BadgeService:AwardBadge` | `BadgeService:AwardBadgeAsync` |
| `BadgeService:UserHasBadge` | `BadgeService:UserHasBadgeAsync` |
| `BadgeService:IsDisabled` / `IsLegal` | `GetBadgeInfoAsync(...).IsEnabled` |

## Teleports

| Don't | Use |
| --- | --- |
| `TeleportService:Teleport`, `TeleportToPlaceInstance`, `TeleportToPrivateServer`, `TeleportPartyAsync`, `TeleportToSpawnByName` | `TeleportService:TeleportAsync` (server) + `TeleportOptions` |
| `TeleportService:ReserveServer` | `ReserveServerAsync` |

## UI, camera, input, sound

| Don't | Use |
| --- | --- |
| `GuiObject:TweenPosition` / `TweenSize` / `TweenSizeAndPosition` | `TweenService` |
| `GuiObject.Draggable`, `DragBegin`, `DragStopped` | `UIDragDetector` |
| `TextLabel/TextButton.FontSize` | `TextSize` |
| `TextColor`, `BackgroundColor`, `BorderColor` | `TextColor3`, `BackgroundColor3`, `BorderColor3` |
| `TextWrap` | `TextWrapped` |
| `Hint`, `Message` | a `TextLabel` in a ScreenGui |
| `Camera.CoordinateFrame` | `Camera.CFrame` |
| `Camera:Interpolate`, `InterpolationFinished` | `TweenService` on `Camera.CFrame` |
| `Mouse.KeyDown` / `KeyUp` | `UserInputService` |
| `UserInputService.ModalEnabled` | `GuiService.TouchControlsEnabled` |
| `UserInputService.VREnabled`, `GetUserCFrame` | `VRService.VREnabled`, `VRService:GetUserCFrame` |
| `HapticService` | `HapticEffect` instances |
| `Sound.Pitch` | `Sound.PlaybackSpeed` |
| `Sound.MinDistance` / `MaxDistance` / `EmitterSize` | `Sound.RollOffMinDistance` / `RollOffMaxDistance` |

## Services and misc

| Don't | Use |
| --- | --- |
| `Chat` service (legacy chat) | `TextChatService` |
| `GlobalDataStore:OnUpdate` | `MessagingService` |
| `TextService:FilterAndTranslateStringAsync` | `TextService:FilterStringAsync` (the old call returns an empty result) |
| `OpenCloudService` | `HttpService` (see the in-experience HTTP requests guide) |
| `HopperBin`, `Hopper` | `Tool`, `StarterPack` |
| `IntConstrainedValue`, `DoubleConstrainedValue` | a number + `math.clamp` |
| `Instance:Remove` | `Instance:Destroy` (or `ClearAllChildren`) |
| `Workspace.FilteringEnabled` | nothing: always on, can't be turned off |
| `Lighting.Technology` | `Lighting.LightingStyle` + `PrioritizeLightingQuality` |
| `CollectionService:GetCollection`, `ItemAdded` | `GetTagged`, `GetInstanceAddedSignal` |

When unsure about anything not listed, open its reference page and look for a deprecation banner:
`https://create.roblox.com/docs/reference/engine/classes/<ClassName>`.
