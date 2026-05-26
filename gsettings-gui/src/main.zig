const std = @import("std");
const gtk = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("gio/gio.h");
});

// GSettings schema
const INTERFACE_SCHEMA = "org.gnome.desktop.interface";

/// Cadenas traducidas según el locale del sistema.
const Locale = enum { en, es };

const L10n = struct {
    window_title: []const u8,
    heading: []const u8,
    tab_themes: []const u8,
    tab_icons: []const u8,
    button_apply: []const u8,
};

fn getStrings(locale: Locale) L10n {
    return switch (locale) {
        .es => .{
            .window_title = "Configurador de Tema e Iconos",
            .heading = "<b>Configuración de GTK</b>",
            .tab_themes = "Temas GTK",
            .tab_icons = "Iconos",
            .button_apply = "Aplicar Cambios",
        },
        .en => .{
            .window_title = "Theme and Icon Configurator",
            .heading = "<b>GTK Configuration</b>",
            .tab_themes = "GTK Themes",
            .tab_icons = "Icons",
            .button_apply = "Apply Changes",
        },
    };
}

fn detectLocale() Locale {
    const lang = std.posix.getenv("LANG") orelse return .en;
    if (std.mem.startsWith(u8, lang, "es")) return .es;
    return .en;
}

pub fn main() !void {
    gtk.gtk_init();

    const app = gtk.gtk_application_new("com.example.GSettingsGUI", 0);

    _ = gtk.g_signal_connect_data(app, "activate", @as(gtk.GCallback, @ptrCast(&activateCallback)), null, null, 0);

    _ = gtk.g_application_run(@ptrCast(app), @intCast(std.os.argv.len), @as([*c][*c]u8, @ptrCast(std.os.argv.ptr)));
}

/// Escanea directorios base en busca de temas/iconos válidos y los agrega a un GtkListBox.
/// Un directorio es válido si contiene un archivo "index.theme".
fn populateListBox(list_box: *gtk.GtkListBox, paths: []const []const u8) void {
    var buf: [std.fs.max_path_bytes]u8 = undefined;

    for (paths) |base_path| {
        var dir = std.fs.openDirAbsolute(base_path, .{ .iterate = true }) catch continue;
        defer dir.close();

        var iter = dir.iterate();
        while (iter.next() catch break) |entry| {
            if (entry.kind != .directory) continue;
            if (entry.name[0] == '.') continue;

            // Verificar que contenga index.theme
            const index_path = std.fmt.bufPrint(&buf, "{s}/index.theme", .{entry.name}) catch continue;
            _ = dir.access(index_path, .{}) catch continue;

            // Crear fila con el nombre del tema/icono
            const label = gtk.gtk_label_new(entry.name.ptr);
            gtk.gtk_widget_set_halign(label, gtk.GTK_ALIGN_START);
            gtk.gtk_widget_set_margin_start(label, 10);
            gtk.gtk_widget_set_margin_end(label, 10);
            gtk.gtk_widget_set_margin_top(label, 6);
            gtk.gtk_widget_set_margin_bottom(label, 6);
            gtk.gtk_list_box_append(@ptrCast(list_box), label);
        }
    }

    // Seleccionar la primera fila si hay alguna
    const first = gtk.gtk_list_box_get_row_at_index(@ptrCast(list_box), 0);
    if (first != null) {
        gtk.gtk_list_box_select_row(@ptrCast(list_box), first);
    }
}

fn activateCallback(app: ?*gtk.GtkApplication, _: ?*anyopaque) callconv(.C) void {
    if (app == null) return;

    const l10n = getStrings(detectLocale());

    // Crear ventana
    const window = gtk.gtk_application_window_new(app);
    gtk.gtk_window_set_title(@ptrCast(window), @ptrCast(l10n.window_title.ptr));
    gtk.gtk_window_set_default_size(@ptrCast(window), 500, 480);

    // Crear caja vertical principal
    const vbox = gtk.gtk_box_new(gtk.GTK_ORIENTATION_VERTICAL, 8);
    gtk.gtk_widget_set_margin_start(vbox, 12);
    gtk.gtk_widget_set_margin_end(vbox, 12);
    gtk.gtk_widget_set_margin_top(vbox, 12);
    gtk.gtk_widget_set_margin_bottom(vbox, 12);
    gtk.gtk_window_set_child(@ptrCast(window), vbox);

    // Título
    const title = gtk.gtk_label_new(@ptrCast(l10n.heading.ptr));
    gtk.gtk_label_set_use_markup(@ptrCast(title), 1);
    gtk.gtk_widget_set_halign(title, gtk.GTK_ALIGN_START);
    gtk.gtk_box_append(@ptrCast(vbox), title);

    // Obtener HOME
    const home = std.posix.getenv("HOME") orelse "";

    // Arena para strings temporales
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Notebook (pestañas)
    const notebook = gtk.gtk_notebook_new();
    gtk.gtk_widget_set_vexpand(notebook, 1);
    gtk.gtk_box_append(@ptrCast(vbox), notebook);

    // --- Pestaña de Temas GTK ---
    const themeTabLabel = gtk.gtk_label_new(@ptrCast(l10n.tab_themes.ptr));
    const themeScrolled = gtk.gtk_scrolled_window_new();
    gtk.gtk_scrolled_window_set_policy(@ptrCast(themeScrolled), gtk.GTK_POLICY_NEVER, gtk.GTK_POLICY_AUTOMATIC);
    gtk.gtk_widget_set_vexpand(themeScrolled, 1);

    const themeListBox = gtk.gtk_list_box_new();
    gtk.gtk_list_box_set_selection_mode(@ptrCast(themeListBox), gtk.GTK_SELECTION_SINGLE);
    gtk.gtk_scrolled_window_set_child(@ptrCast(themeScrolled), themeListBox);

    const home_themes = std.fmt.allocPrint(allocator, "{s}/.themes", .{home}) catch return;
    populateListBox(@ptrCast(themeListBox), &[_][]const u8{ "/usr/share/themes", home_themes });

    _ = gtk.gtk_notebook_append_page(@ptrCast(notebook), themeScrolled, themeTabLabel);

    // --- Pestaña de Iconos ---
    const iconTabLabel = gtk.gtk_label_new(@ptrCast(l10n.tab_icons.ptr));
    const iconScrolled = gtk.gtk_scrolled_window_new();
    gtk.gtk_scrolled_window_set_policy(@ptrCast(iconScrolled), gtk.GTK_POLICY_NEVER, gtk.GTK_POLICY_AUTOMATIC);
    gtk.gtk_widget_set_vexpand(iconScrolled, 1);

    const iconListBox = gtk.gtk_list_box_new();
    gtk.gtk_list_box_set_selection_mode(@ptrCast(iconListBox), gtk.GTK_SELECTION_SINGLE);
    gtk.gtk_scrolled_window_set_child(@ptrCast(iconScrolled), iconListBox);

    const home_icons = std.fmt.allocPrint(allocator, "{s}/.local/share/icons", .{home}) catch return;
    populateListBox(@ptrCast(iconListBox), &[_][]const u8{ "/usr/share/icons", home_icons });

    _ = gtk.gtk_notebook_append_page(@ptrCast(notebook), iconScrolled, iconTabLabel);

    // Botón Aplicar
    const applyButton = gtk.gtk_button_new_with_label(@ptrCast(l10n.button_apply.ptr));
    gtk.gtk_widget_set_halign(applyButton, gtk.GTK_ALIGN_CENTER);
    gtk.gtk_widget_set_margin_top(applyButton, 8);

    // Datos para el callback — incluir el locale para los mensajes
    const CallbackData = struct {
        theme_list: ?*anyopaque,
        icon_list: ?*anyopaque,
        locale: Locale,
    };

    const data = std.heap.c_allocator.create(CallbackData) catch return;
    data.* = CallbackData{
        .theme_list = themeListBox,
        .icon_list = iconListBox,
        .locale = detectLocale(),
    };

    _ = gtk.g_signal_connect_data(applyButton, "clicked", @as(gtk.GCallback, @ptrCast(&onApplyClicked)), data, null, 0);
    gtk.gtk_box_append(@ptrCast(vbox), applyButton);

    // Mostrar ventana
    gtk.gtk_window_present(@ptrCast(window));
}

fn onApplyClicked(button: ?*gtk.GtkButton, data: ?*anyopaque) callconv(.C) void {
    _ = button;
    if (data == null) return;

    const CallbackData = struct {
        theme_list: ?*anyopaque,
        icon_list: ?*anyopaque,
        locale: Locale,
    };

    const callback_data: *CallbackData = @ptrCast(@alignCast(data.?));

    // Aplicar tema GTK
    const themeRow = gtk.gtk_list_box_get_selected_row(@alignCast(@ptrCast(callback_data.theme_list)));
    if (themeRow != null) {
        const child = gtk.gtk_list_box_row_get_child(@ptrCast(themeRow));
        const themeName = gtk.gtk_label_get_text(@ptrCast(child));
        if (themeName != null) {
            const settings = gtk.g_settings_new(INTERFACE_SCHEMA);
            defer gtk.g_object_unref(settings);
            _ = gtk.g_settings_set_string(settings, "gtk-theme", themeName);
            switch (callback_data.locale) {
                .en => std.debug.print("GTK theme applied: {s}\n", .{themeName}),
                .es => std.debug.print("Tema GTK aplicado: {s}\n", .{themeName}),
            }
        }
    }

    // Aplicar tema de iconos
    const iconRow = gtk.gtk_list_box_get_selected_row(@alignCast(@ptrCast(callback_data.icon_list)));
    if (iconRow != null) {
        const child = gtk.gtk_list_box_row_get_child(@ptrCast(iconRow));
        const iconName = gtk.gtk_label_get_text(@ptrCast(child));
        if (iconName != null) {
            const settings = gtk.g_settings_new(INTERFACE_SCHEMA);
            defer gtk.g_object_unref(settings);
            _ = gtk.g_settings_set_string(settings, "icon-theme", iconName);
            switch (callback_data.locale) {
                .en => std.debug.print("Icon theme applied: {s}\n", .{iconName}),
                .es => std.debug.print("Tema de iconos aplicado: {s}\n", .{iconName}),
            }
        }
    }

    switch (callback_data.locale) {
        .en => std.debug.print("Changes applied!\n", .{}),
        .es => std.debug.print("¡Cambios aplicados!\n", .{}),
    }
}
