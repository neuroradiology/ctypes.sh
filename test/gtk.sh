#!/bin/bash

# This is a port of the GTK+3 Hello World to bash.
#
# https://developer.gnome.org/gtk3/stable/gtk-getting-started.html
source ../ctypes.sh

# declare some numeric constants used by GTK+
declare -ri GTK_ORIENTATION_HORIZONTAL=0
declare -ri G_APPLICATION_FLAGS_NONE=0
declare -ri G_CONNECT_AFTER=$((1 << 0))
declare -ri G_CONNECT_SWAPPED=$((1 << 1))

set -ex

# void print_hello(GtkApplication *app, gpointer user_data)
function print_hello() {
    dlcall $RTLD_DEFAULT g_print $'Hello World\n'
}

# void activate(GtkApplication *app, gpointer user_data)
function activate() {
    local app=$3
    local user_data=$2
    local window
    local button
    local button_box

    dlsym -n gtk_widget_destroy $RTLD_DEFAULT gtk_widget_destroy

    dlcall -n window -r pointer $RTLD_DEFAULT gtk_application_window_new $app
    dlcall $RTLD_DEFAULT gtk_window_set_title $window "Window"
    dlcall $RTLD_DEFAULT gtk_window_set_default_size $window 200 200
    
    dlcall -n button_box -r pointer $RTLD_DEFAULT gtk_button_box_new $GTK_ORIENTATION_HORIZONTAL
    dlcall $RTLD_DEFAULT gtk_container_add $window $button_box
    
    dlcall -n button -r pointer $RTLD_DEFAULT gtk_button_new_with_label "Hello World"
    dlcall $RTLD_DEFAULT g_signal_connect_data $button "clicked" $print_hello $NULL $NULL 0
    dlcall $RTLD_DEFAULT g_signal_connect_data $button "clicked" $gtk_widget_destroy $window $NULL 
    dlcall $RTLD_DEFAULT gtk_container_add $button_box $button

    dlcall $RTLD_DEFAULT gtk_widget_show_all $window
}

declare app     # GtkApplication *app
declare status  # int status

# Generate function pointers that can be called from native code.
callback -n print_hello print_hello void pointer pointer
callback -n activate activate void pointer pointer

# Make libgtk3 symbols available at global scope
dlopen -g libgtk-3.so.0

dlcall -n app -r pointer $RTLD_DEFAULT gtk_application_new "org.gtk.example" $G_APPLICATION_FLAGS_NONE
dlcall $RTLD_DEFAULT g_signal_connect_data $app "activate" $activate $NULL $NULL 0
dlcall -n status -r int $RTLD_DEFAULT g_application_run $app 0 $NULL
dlcall $RTLD_DEFAULT g_object_unref $app

exit ${status##*:}