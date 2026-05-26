# GUI para GSettings en Zig + GTK4

Una aplicación ligera para configurar temas GTK e iconos usando GSettings.

## Requisitos

- Zig 0.13.0 o superior
- GTK4 y sus dependencias
- GNOME/GSettings instalado

### Instalar dependencias en Debian/Ubuntu:

```bash
sudo apt-get install libgtk-4-dev libglib2.0-dev
```

## Compilación

```bash
zig build
```

## Ejecución

```bash
zig build run
```

O directamente el binario:

```bash
./zig-out/bin/gsettings-gui
```

## Características

- Configurar tema GTK (Adwaita, Adwaita-dark, HighContrast)
- Configurar tema de iconos (Adwaita, Adwaita-symbolic, hicolor)
- Interfaz simple y ligera
- Usa GSettings nativo de GNOME

## Notas

Esta aplicación modifica la configuración de GNOME a través de GSettings.
Los cambios se aplican inmediatamente al sistema.
