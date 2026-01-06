## Description
- When a Player types in chat, a Floating Message appears above their head, visible to nearby Players who can see and read it.

![20251211233926_1](https://github.com/user-attachments/assets/fd607de2-2608-4d82-805e-6dde8353fcce)

## More
- **Supports** All Languages. **(Probably)**
- **Supports** 32+ Player Servers. **(Probably)**
- **Supports** **[Basecomm](https://github.com/alliedmodders/sourcemod/blob/master/plugins/basecomm.sp)** and **[SourceComms](https://github.com/sbpp/sourcebans-pp)**.
- **Supports** Say Team, Team Chat Annotations are only visible to Teammates.
- **Annotations** do **Not Penetrate Walls**.
- **Spy Cloak / Disguise**, Chat Annotation Not Working.

## Difference From [TF2-ChatBubbles](https://github.com/DosMike/TF2-ChatBubbles)
- **ConVar Mores**.
- **No Dependencies**.
- **Supports Ban Gag / Silence**.

## Command
- `sm_annotations` - Chat Annotations Settings
- `sm_annotation` - Chat Annotations Settings
- `sm_annotate` - Chat Annotations Settings
- `sm_ann` - Chat Annotations Settings

## ConVar
|Name|Default Value|Description|
|-|:-:|-|
|`sm_cvann_version`|`6.6.0`|Version of TF2Chat Annotations.|
|`sm_cvann_enable`|`1`|TF2Chat Annotations.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_range`|`25`|Distance to See Annotations.|
|`sm_cvann_show_range`|`1`|Show Distance to speaker in Annotations.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_show_msg`|`1`|Allow Players to See their own Chat Annotation.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_show_cmd`|`1`|Command Visibility.<br>(0 = Hide `!` and `/`, 1 = Hide `/`, 2 = Hide `!`, 3 = Show `!` and `/`)|
|`sm_cvann_interval`|`0.5`|Update interval for checking Annotation Visibility.|
|`sm_cvann_lifetime`|`10.0`|How long Message stays visible (Seconds).|
|`sm_cvann_sound`|`ui/hint.wav`|Sound File to play when Annotation Appears.<br>(Empty = No sound)|
|`sm_cvann_limit`|`5`|Maximum Number of Annotations shown at same time.<br>(0 = Unlimited)|
|`sm_cvann_maxlen`|`64`|Maximum Length of Chat Message shown in Annotations.|
|`sm_cvann_cmd_chat`|`1`|Default Chat Command.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_cmd_sound`|`0`|Default Sound Command.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_cmd_range`|`0`|Default Range Command.<br>(1 = Enable, 0 = Disable)|
|`sm_cvann_entity_remove`|`1900`|Remove All Annotations if Entity count reaches this.|
|`sm_cvann_entity_block`|`2000`|Block New Annotations if Entity count reaches this.|

## Credit
- [Heapons](https://github.com/Heapons/TF2-Chat-Annotations) - Edit Code
