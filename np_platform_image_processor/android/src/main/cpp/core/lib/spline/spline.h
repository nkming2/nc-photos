/*
 * spline.h
 *
 * simple cubic spline interpolation library without external
 * dependencies
 *
 * ---------------------------------------------------------------------
 * Copyright (C) 2011, 2014, 2016, 2021 Tino Kluge (ttk448 at gmail.com)
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * ---------------------------------------------------------------------
 *
 */

#pragma once

#include <cassert>
#include <string>
#include <vector>

namespace tk {

// spline interpolation
class spline {
public:
  // spline types
  enum spline_type {
    linear = 10,         // linear interpolation
    cspline = 30,        // cubic splines (classical C^2)
    cspline_hermite = 31 // cubic hermite splines (local, only C^1)
  };

  // boundary condition type for the spline end-points
  enum bd_type { first_deriv = 1, second_deriv = 2, not_a_knot = 3 };

protected:
  std::vector<double> m_x, m_y; // x,y coordinates of points
  // interpolation parameters
  // f(x) = a_i + b_i*(x-x_i) + c_i*(x-x_i)^2 + d_i*(x-x_i)^3
  // where a_i = y_i, or else it won't go through grid points
  std::vector<double> m_b, m_c, m_d; // spline coefficients
  double m_c0;                       // for left extrapolation
  spline_type m_type;
  bd_type m_left, m_right;
  double m_left_value, m_right_value;
  bool m_made_monotonic;
  void set_coeffs_from_b();            // calculate c_i, d_i from b_i
  size_t find_closest(double x) const; // closest idx so that m_x[idx]<=x

public:
  // default constructor: set boundary condition to be zero curvature
  // at both ends, i.e. natural splines
  spline()
      : m_type(cspline), m_left(second_deriv), m_right(second_deriv),
        m_left_value(0.0), m_right_value(0.0), m_made_monotonic(false) {
    ;
  }
  spline(const std::vector<double> &X, const std::vector<double> &Y,
         spline_type type = cspline, bool make_monotonic = false,
         bd_type left = second_deriv, double left_value = 0.0,
         bd_type right = second_deriv, double right_value = 0.0)
      : m_type(type), m_left(left), m_right(right), m_left_value(left_value),
        m_right_value(right_value),
        m_made_monotonic(false) // false correct here: make_monotonic() sets it
  {
    this->set_points(X, Y, m_type);
    if (make_monotonic) {
      this->make_monotonic();
    }
  }

  // modify boundary conditions: if called it must be before set_points()
  void set_boundary(bd_type left, double left_value, bd_type right,
                    double right_value);

  // set all data points (cubic_spline=false means linear interpolation)
  void set_points(const std::vector<double> &x, const std::vector<double> &y,
                  spline_type type = cspline);

  // adjust coefficients so that the spline becomes piecewise monotonic
  // where possible
  //   this is done by adjusting slopes at grid points by a non-negative
  //   factor and this will break C^2
  //   this can also break boundary conditions if adjustments need to
  //   be made at the boundary points
  // returns false if no adjustments have been made, true otherwise
  bool make_monotonic();

  // evaluates the spline at point x
  double operator()(double x) const;
  double deriv(int order, double x) const;

  // solves for all x so that: spline(x) = y
  std::vector<double> solve(double y, bool ignore_extrapolation = true) const;

  // returns the input data points
  std::vector<double> get_x() const { return m_x; }
  std::vector<double> get_y() const { return m_y; }
  double get_x_min() const {
    assert(!m_x.empty());
    return m_x.front();
  }
  double get_x_max() const {
    assert(!m_x.empty());
    return m_x.back();
  }

  // spline info string, i.e. spline type, boundary conditions etc.
  std::string info() const;
};

} // namespace tkPLINE_H */
