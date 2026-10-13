// Печатная катушка для троса на D-вал 6 мм мотор-редуктора JGY-370 (лифт лампы QB288).
// Все размеры в мм. Ось катушки Z, z = 0 это торец, обращённый к редуктору.
// Версия «compact» (по умолчанию STL spool_compact.stl): hub_len = 0, flange_t = 2.5, stub_h = 0, фиксация клеем.
// Версия «screw» (spool_screw.stl): hub_len = 4, flange_t = 3.5, stub_h = 8, фиксация винтом M3 через гайку M3.
//
// Размеры вала проверены по чертежам Aslong и Handson: Ø6, лыска 5,4 (5,3..5,5), длина лыски 8..12 от торца,
// длина вала 14 от бобышки подшипника. ИЗМЕРЬТЕ штангенциркулем свой вал и поправьте flat_f и shaft_len.

$fn = 96;

// --- вал мотора ---
shaft_d   = 6.0;   // диаметр вала
flat_f    = 5.4;   // от лыски до противоположной стороны вала
shaft_len = 14.0;  // длина вала от торца бобышки подшипника
gap       = 0.5;   // зазор между катушкой и бобышкой
d_len     = 8.0;   // консервативная длина лыски от конца вала
spare     = 1.0;   // запас глубины отверстия за концом вала
clear     = 0.10;  // зазор на сторону (0,2 на диаметр и на размер по лыске)

// --- ступица с гайкой M3 под стопорный винт (hub_len = 0 отключает ступицу и гайку) ---
hub_len = 4.0;  hub_d = 18.0;
nut_af = 5.7;   nut_ac = 6.7;  nut_t = 2.6;  nut_x = 4.4;  nut_z = 3.0;
screw_hole_d = 3.4;

// --- катушка ---
flange_d = 38.0;  flange_t = 3.5;  outer_flange_t = 3.0;
core_d   = 26.0;  wind_w   = 15.0;
rope_d = 1.5;  pitch = 1.8;  groove_r = 0.85;  groove_depth = 1.0;
anchor_d = 2.2;  anchor_recess_d = 6.5;  anchor_recess_h = 1.6;
stub_d = 6.1;  stub_h = 8.0;       // глухое отверстие на наружном торце под штифт Ø6 (опорный подшипник), 0 = нет

print_orientation = true;          // true: наружная щёчка на столе, ступица вверх

// --- вычисляемое ---
r_core = core_d / 2;  r_fl = flange_d / 2;  r_hub = hub_d / 2;
z_wind0 = hub_len + flange_t;
z_wind1 = z_wind0 + wind_w;
z_end   = z_wind1 + outer_flange_t;
r_b     = shaft_d / 2 + clear;
flat_x  = flat_f - shaft_d / 2 + clear;
z_tip   = shaft_len + gap;
depth   = z_tip + spare;
z_d0    = z_tip - d_len;
twist_total = 360 * wind_w / pitch;
r_gc    = r_core - groove_depth + groove_r;

module body() {
    if (hub_len > 0) {
        cylinder(h = hub_len + 0.01, r = r_hub);
        translate([0, 0, hub_len]) cylinder(h = flange_t, r = r_fl);
    } else {
        cylinder(h = flange_t, r = r_fl);
    }
    translate([0, 0, z_wind0 - 0.01]) cylinder(h = wind_w + 0.02, r = r_core);
    translate([0, 0, z_wind1]) cylinder(h = outer_flange_t, r = r_fl);
}

module d_profile() {
    intersection() {
        circle(r = r_b, $fn = 64);
        translate([-r_b - 1, -r_b - 1]) square([flat_x + r_b + 1, 2 * r_b + 2]);
    }
}

// Горизонтальное сечение винтовой канавки с шагом pitch: на радиусе r канавка занимает угол +-a(r),
// a = 360 * w(r) / (2 * pitch), w(r) осевая ширина круглого профиля канавки на этом радиусе.
module groove_section() {
    n_t = 90;                                   // шаг по параметру профиля 2 градуса
    polygon(concat(
        [for (i = [0 : n_t])
            let(t = -90 + 2 * i, r = r_gc + groove_r * sin(t), a = 360 * groove_r * cos(t) / pitch)
            [r * cos(-a), r * sin(-a)]],
        [for (i = [n_t - 1 : -1 : 1])
            let(t = -90 + 2 * i, r = r_gc + groove_r * sin(t), a = 360 * groove_r * cos(t) / pitch)
            [r * cos(a), r * sin(a)]]
    ));
}

module cutouts() {
    // круглое устье отверстия
    translate([0, 0, -0.2]) cylinder(h = z_d0 + 0.25, r = r_b, $fn = 64);
    // D-часть у конца вала
    translate([0, 0, z_d0 - 0.05]) linear_extrude(height = depth - z_d0 + 0.05) d_profile();
    // фаска на входе
    translate([0, 0, -0.01]) cylinder(h = 0.6, r1 = r_b + 0.6, r2 = r_b, $fn = 64);

    if (hub_len > 0) {
        // паз под гайку M3 от торца z = 0 и отверстие под винт, оба вдоль +X
        translate([nut_x, -nut_af / 2, -1]) cube([nut_t, nut_af, nut_z + nut_ac / 2 + 1]);
        translate([r_b - 0.8, 0, nut_z]) rotate([0, 90, 0])
            cylinder(h = r_hub + 1 - (r_b - 0.8), d = screw_hole_d, $fn = 32);
    }

    // винтовая канавка под трос: профиль полукруглый, конец канавки на наружной щёчке в точке отверстия для троса
    translate([0, 0, z_wind0 - 0.01]) rotate([0, 0, -twist_total])
        linear_extrude(height = wind_w + 0.02, twist = -twist_total, slices = round(twist_total / 8), convexity = 10)
            groove_section();

    // отверстие для троса сквозь наружную щёчку и выемка под узел или обжимную гильзу
    translate([r_gc, 0, z_wind1 - 0.3]) cylinder(h = outer_flange_t + 0.5, d = anchor_d, $fn = 32);
    translate([r_gc, 0, z_end - anchor_recess_h]) cylinder(h = anchor_recess_h + 0.2, d = anchor_recess_d, $fn = 32);

    // гнездо под штифт опорного подшипника на наружном торце
    if (stub_h > 0)
        translate([0, 0, z_end - stub_h]) cylinder(h = stub_h + 0.2, d = stub_d, $fn = 48);
}

module spool() {
    difference() {
        body();
        cutouts();
    }
}

if (print_orientation)
    translate([0, 0, z_end]) rotate([180, 0, 0]) spool();
else
    spool();
