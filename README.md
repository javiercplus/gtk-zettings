# GUI for GSettings in Zig + GTK4

A lightweight application to configure GTK themes and icons using GSettings.

## Requirements

- Zig 0.13.0 or higher
- GTK4 and its dependencies
- GNOME/GSettings installed

## Compilation

```bash
zig build
```

## Execution

```bash
zig build run
```

Or directly the binary:

```bash
./zig-out/bin/gsettings-gui
```

## Features

- Configure GTK theme (Adwaita, Adwaita-dark, HighContrast)
- Configure icon theme (Adwaita, Adwaita-symbolic, hicolor)
- Simple and lightweight interface
- Uses native GNOME GSettings

## Notes

This application modifies GNOME settings through GSettings.
Changes are applied to the system immediately.
