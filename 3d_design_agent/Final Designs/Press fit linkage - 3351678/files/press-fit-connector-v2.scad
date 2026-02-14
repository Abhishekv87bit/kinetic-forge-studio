bearing_height = 7.25;
bearing_outer_diameter = 22.38;
bearing_inner_diameter = 7.89;
link_length = 55;
end_effector_angle = -60;
end_effector_length = 40;
num_layers = 1;
end_effector_layers = 2;
$fn = 50;

module press_fit_link(
  bearing_height,
  bearing_outer_diameter,
  bearing_inner_diameter,
  link_length,
  end_effector_angle,
  end_effector_length,
  outer_diameter_margin=3,
  inner_diameter_margin=2,
  link_layer_margin=1.8,
  num_layers=1, /* zero turns it into an outter bearing */
  end_effector_layers=0, /* TODO: implement 0 */
) {
  link_width = bearing_inner_diameter + inner_diameter_margin;

  layer_height = bearing_height + link_layer_margin;

  module outter_bearing_inside() {
    cylinder(h=bearing_height + 100, d=bearing_outer_diameter);
  }

  module outter_bearing_outside() {
    cylinder(h=bearing_height, d=bearing_outer_diameter + outer_diameter_margin);
  }

  module inner_bearing_positive(num_layers) {
    if (num_layers > 0) {
      // inner base and tower
      cylinder(h=bearing_height + link_layer_margin, d=link_width);
      cylinder(
        h=bearing_height * 2 + link_layer_margin + (num_layers - 1) * layer_height,
        d=bearing_inner_diameter
      );

      // inner spacers
      if (num_layers > 1) {
        %translate([0, 0, bearing_height])
        for (i = [0: num_layers - 2]) {
          translate([0, 0, (i + 1) * (bearing_height + link_layer_margin)])
          cylinder(h=link_layer_margin, d=link_width);
        }
      }
    }
  }

  module negative() {
    translate([0, 0, -1]) {
      outter_bearing_inside();

      if (num_layers == 0) {
        translate([link_length, 0, 0])
        outter_bearing_inside();
      }
    }
  }

  module positive() {
    // outter 1
    outter_bearing_outside();

    // link from 1 to 2
    translate([0, -link_width / 2, 0])
    cube([link_length, link_width, bearing_height]);

    // inner or outter 2
    translate([link_length, 0, 0]) {
      if (num_layers == 0) {
        // 0 -> outter 2
        outter_bearing_outside();
      } else if (num_layers > 0) {
        // >0 -> inner 2
        inner_bearing_positive(num_layers);
      }
    }

    // end effector (from 2 to 3)
    translate([link_length, 0, 0])
    rotate([0, 0, end_effector_angle]) {
      translate([0, -link_width / 2, 0])
      cube([end_effector_length, link_width, bearing_height]);

      translate([end_effector_length, 0, 0]) {
        cylinder(h=bearing_height, d=link_width);
        inner_bearing_positive(end_effector_layers);
      }
    }

    // link from 1 to 3
    hull() {
      cylinder(h=bearing_height, d=link_width);
      translate([link_length, 0, 0])
      rotate([0, 0, end_effector_angle])
      translate([end_effector_length, 0, 0])
      cylinder(h=bearing_height, d=link_width);
    }
  }

  difference() {
    positive();
    negative();
  }
}

module spacer(
  bearing_height,
  bearing_outer_diameter,
  bearing_inner_diameter,
  link_length,
  end_effector_angle,
  end_effector_length,
  outer_diameter_margin=3,
  inner_diameter_margin=2,
  link_layer_margin=1.8,
  num_layers=1, /* zero turns it into an outter bearing */
  end_effector_layers=0, /* TODO: implement 0 */
) {
  link_width = bearing_inner_diameter + inner_diameter_margin;
  difference() {
    cylinder(h=link_layer_margin, d=link_width);
    cylinder(h=100, d=bearing_inner_diameter, center=true);
  }
}

press_fit_link(
  bearing_height=bearing_height,
  bearing_outer_diameter=bearing_outer_diameter,
  bearing_inner_diameter=bearing_inner_diameter,
  link_length=link_length,
  num_layers=num_layers,
  end_effector_layers=end_effector_layers,
  end_effector_angle=end_effector_angle,
  end_effector_length=end_effector_length
);
