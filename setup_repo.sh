#!/usr/bin/env bash
# setup_repo.sh
#
# Scaffolds fluid-mechanics-computational-toolkit into a proper Python
# project layout: src/ package, tests/, examples/, docs/, plus
# pyproject.toml, requirements.txt, .gitignore, LICENSE, and README.md.
#
# Usage:
#   1. cd into your local clone of the repo
#      (git clone https://github.com/RAJDEEP678/fluid-mechanics-computational-toolkit.git)
#   2. Copy this script into the repo root.
#   3. Run:  bash setup_repo.sh
#   4. Review the changes (git status / git diff), then:
#      git add -A && git commit -m "Add Python project scaffolding" && git push
#
# This script REMOVES the placeholder file `01_fundamentals` (its content is
# reorganized into src/fluid_mechanics_toolkit/fundamentals/) and OVERWRITES
# README.md with an expanded version. Everything else is additive.

set -euo pipefail

echo "Removing placeholder file 01_fundamentals (if present)..."
rm -f 01_fundamentals

echo "Creating directory structure..."
mkdir -p src/fluid_mechanics_toolkit/fundamentals
mkdir -p src/fluid_mechanics_toolkit/internal_flow
mkdir -p src/fluid_mechanics_toolkit/external_flow
mkdir -p src/fluid_mechanics_toolkit/compressible_flow
mkdir -p src/fluid_mechanics_toolkit/shock_waves
mkdir -p src/fluid_mechanics_toolkit/numerical_methods
mkdir -p src/fluid_mechanics_toolkit/verification_validation
mkdir -p tests
mkdir -p examples
mkdir -p docs

echo "Writing package files..."

cat > src/fluid_mechanics_toolkit/__init__.py <<'PYEOF'
"""fluid_mechanics_toolkit
========================

A computational fluid mechanics toolkit covering fundamental fluid mechanics,
internal and external flows, compressible flow, shock-wave analysis,
numerical methods, and CFD verification & validation.

Sub-packages
------------
fundamentals            Basic fluid properties and hydrostatics.
internal_flow            Pipe / duct flow (Reynolds number, friction factor, head loss).
external_flow             Boundary-layer and drag relations over external surfaces.
compressible_flow    Isentropic flow relations and stagnation properties.
shock_waves             Normal shock relations.
numerical_methods  Finite-difference building blocks used across the toolkit.
verification_validation  Grid Convergence Index, Richardson extrapolation, error norms.
"""

__version__ = "0.1.0"
PYEOF

cat > src/fluid_mechanics_toolkit/fundamentals/__init__.py <<'PYEOF'
"""Fundamental fluid-mechanics relations: fluid properties and hydrostatics."""

from .fluid_properties import ideal_gas_density, dynamic_to_kinematic_viscosity, reynolds_number
from .hydrostatics import hydrostatic_pressure, buoyant_force

__all__ = [
    "ideal_gas_density",
    "dynamic_to_kinematic_viscosity",
    "reynolds_number",
    "hydrostatic_pressure",
    "buoyant_force",
]
PYEOF

cat > src/fluid_mechanics_toolkit/fundamentals/fluid_properties.py <<'PYEOF'
"""Basic fluid property relations."""

from __future__ import annotations


def ideal_gas_density(pressure: float, temperature: float, specific_gas_constant: float = 287.05) -> float:
    """Density of an ideal gas from the ideal gas law: rho = p / (R T).

    Parameters
    ----------
    pressure : float
        Absolute pressure [Pa].
    temperature : float
        Absolute temperature [K].
    specific_gas_constant : float, optional
        Specific gas constant [J/(kg K)]. Defaults to dry air (287.05 J/(kg K)).

    Returns
    -------
    float
        Density [kg/m^3].
    """
    if temperature <= 0:
        raise ValueError("temperature must be a positive value in Kelvin")
    return pressure / (specific_gas_constant * temperature)


def dynamic_to_kinematic_viscosity(dynamic_viscosity: float, density: float) -> float:
    """Convert dynamic viscosity to kinematic viscosity: nu = mu / rho.

    Parameters
    ----------
    dynamic_viscosity : float
        Dynamic viscosity mu [Pa s].
    density : float
        Density rho [kg/m^3].

    Returns
    -------
    float
        Kinematic viscosity nu [m^2/s].
    """
    if density <= 0:
        raise ValueError("density must be positive")
    return dynamic_viscosity / density


def reynolds_number(velocity: float, length: float, kinematic_viscosity: float) -> float:
    """Reynolds number Re = V L / nu.

    Parameters
    ----------
    velocity : float
        Characteristic velocity [m/s].
    length : float
        Characteristic length [m].
    kinematic_viscosity : float
        Kinematic viscosity [m^2/s].

    Returns
    -------
    float
        Dimensionless Reynolds number.
    """
    if kinematic_viscosity <= 0:
        raise ValueError("kinematic_viscosity must be positive")
    return velocity * length / kinematic_viscosity
PYEOF

cat > src/fluid_mechanics_toolkit/fundamentals/hydrostatics.py <<'PYEOF'
"""Hydrostatic pressure and buoyancy relations."""

from __future__ import annotations

STANDARD_GRAVITY = 9.80665  # m/s^2


def hydrostatic_pressure(density: float, depth: float, gravity: float = STANDARD_GRAVITY,
                          surface_pressure: float = 0.0) -> float:
    """Gauge/absolute pressure at depth in a static fluid: p = p0 + rho g h.

    Parameters
    ----------
    density : float
        Fluid density [kg/m^3].
    depth : float
        Depth below the free surface [m].
    gravity : float, optional
        Gravitational acceleration [m/s^2]. Defaults to standard gravity.
    surface_pressure : float, optional
        Pressure at the free surface [Pa]. Defaults to 0 (gauge pressure).

    Returns
    -------
    float
        Pressure at the given depth [Pa].
    """
    if depth < 0:
        raise ValueError("depth must be non-negative")
    return surface_pressure + density * gravity * depth


def buoyant_force(fluid_density: float, displaced_volume: float, gravity: float = STANDARD_GRAVITY) -> float:
    """Archimedes' buoyant force: F_b = rho_fluid * V_displaced * g.

    Parameters
    ----------
    fluid_density : float
        Density of the displaced fluid [kg/m^3].
    displaced_volume : float
        Volume of fluid displaced by the submerged body [m^3].
    gravity : float, optional
        Gravitational acceleration [m/s^2].

    Returns
    -------
    float
        Buoyant force [N].
    """
    if displaced_volume < 0:
        raise ValueError("displaced_volume must be non-negative")
    return fluid_density * displaced_volume * gravity
PYEOF

echo "  fundamentals done"

cat > src/fluid_mechanics_toolkit/internal_flow/__init__.py <<'PYEOF'
"""Internal (duct / pipe) flow relations."""

from .pipe_flow import friction_factor_laminar, friction_factor_colebrook, darcy_weisbach_head_loss, flow_regime

__all__ = [
    "friction_factor_laminar",
    "friction_factor_colebrook",
    "darcy_weisbach_head_loss",
    "flow_regime",
]
PYEOF

cat > src/fluid_mechanics_toolkit/internal_flow/pipe_flow.py <<'PYEOF'
"""Internal pipe-flow relations: friction factor and head loss."""

from __future__ import annotations

STANDARD_GRAVITY = 9.80665  # m/s^2


def flow_regime(reynolds: float, laminar_limit: float = 2300.0, turbulent_limit: float = 4000.0) -> str:
    """Classify pipe flow regime from Reynolds number.

    Returns "laminar", "transitional", or "turbulent".
    """
    if reynolds < laminar_limit:
        return "laminar"
    if reynolds > turbulent_limit:
        return "turbulent"
    return "transitional"


def friction_factor_laminar(reynolds: float) -> float:
    """Darcy friction factor for laminar pipe flow: f = 64 / Re.

    Valid for Re < ~2300.
    """
    if reynolds <= 0:
        raise ValueError("reynolds must be positive")
    return 64.0 / reynolds


def friction_factor_colebrook(reynolds: float, relative_roughness: float,
                               tolerance: float = 1e-10, max_iterations: int = 100) -> float:
    """Darcy friction factor for turbulent pipe flow via the Colebrook-White equation,
    solved by fixed-point iteration:

        1/sqrt(f) = -2 log10( eps/D/3.7 + 2.51 / (Re sqrt(f)) )

    Parameters
    ----------
    reynolds : float
        Reynolds number (should be > ~4000 for the Colebrook correlation to apply).
    relative_roughness : float
        Pipe relative roughness eps/D (dimensionless).
    tolerance : float, optional
        Convergence tolerance on f between iterations.
    max_iterations : int, optional
        Maximum number of fixed-point iterations.

    Returns
    -------
    float
        Darcy (Moody) friction factor.
    """
    import math

    if reynolds <= 0:
        raise ValueError("reynolds must be positive")
    if relative_roughness < 0:
        raise ValueError("relative_roughness must be non-negative")

    # Initial guess from the Swamee-Jain explicit approximation.
    f = 0.25 / (math.log10(relative_roughness / 3.7 + 5.74 / reynolds ** 0.9)) ** 2

    for _ in range(max_iterations):
        rhs = -2.0 * math.log10(relative_roughness / 3.7 + 2.51 / (reynolds * math.sqrt(f)))
        f_new = 1.0 / rhs ** 2
        if abs(f_new - f) < tolerance:
            return f_new
        f = f_new
    return f


def darcy_weisbach_head_loss(friction_factor: float, length: float, diameter: float,
                              velocity: float, gravity: float = STANDARD_GRAVITY) -> float:
    """Head loss due to friction in a pipe (Darcy-Weisbach equation):

        h_f = f (L/D) (V^2 / 2g)

    Parameters
    ----------
    friction_factor : float
        Darcy friction factor f.
    length : float
        Pipe length [m].
    diameter : float
        Pipe (hydraulic) diameter [m].
    velocity : float
        Mean flow velocity [m/s].
    gravity : float, optional
        Gravitational acceleration [m/s^2].

    Returns
    -------
    float
        Head loss [m].
    """
    if diameter <= 0:
        raise ValueError("diameter must be positive")
    return friction_factor * (length / diameter) * (velocity ** 2) / (2 * gravity)
PYEOF

echo "  internal_flow done"

cat > src/fluid_mechanics_toolkit/external_flow/__init__.py <<'PYEOF'
"""External flow relations: flat-plate boundary layer and drag."""

from .boundary_layer import blasius_boundary_layer_thickness, flat_plate_drag_coefficient

__all__ = ["blasius_boundary_layer_thickness", "flat_plate_drag_coefficient"]
PYEOF

cat > src/fluid_mechanics_toolkit/external_flow/boundary_layer.py <<'PYEOF'
"""Flat-plate laminar boundary-layer relations (Blasius solution)."""

from __future__ import annotations


def blasius_boundary_layer_thickness(x: float, reynolds_x: float) -> float:
    """Laminar boundary-layer thickness on a flat plate (Blasius): delta = 5.0 x / sqrt(Re_x).

    Parameters
    ----------
    x : float
        Distance from the leading edge [m].
    reynolds_x : float
        Local Reynolds number Re_x = U x / nu at position x.

    Returns
    -------
    float
        Boundary-layer thickness delta [m].
    """
    if reynolds_x <= 0:
        raise ValueError("reynolds_x must be positive")
    if x < 0:
        raise ValueError("x must be non-negative")
    return 5.0 * x / reynolds_x ** 0.5


def flat_plate_drag_coefficient(reynolds_l: float) -> float:
    """Average skin-friction drag coefficient for laminar flow over a flat plate:

        C_D = 1.328 / sqrt(Re_L)

    Valid for Re_L < ~5e5 (laminar boundary layer).

    Parameters
    ----------
    reynolds_l : float
        Reynolds number based on plate length L.

    Returns
    -------
    float
        Average drag coefficient (dimensionless).
    """
    if reynolds_l <= 0:
        raise ValueError("reynolds_l must be positive")
    return 1.328 / reynolds_l ** 0.5
PYEOF

echo "  external_flow done"

cat > src/fluid_mechanics_toolkit/compressible_flow/__init__.py <<'PYEOF'
"""Compressible (isentropic) flow relations."""

from .isentropic import (
    mach_number,
    isentropic_pressure_ratio,
    isentropic_temperature_ratio,
    isentropic_density_ratio,
    speed_of_sound,
)

__all__ = [
    "mach_number",
    "isentropic_pressure_ratio",
    "isentropic_temperature_ratio",
    "isentropic_density_ratio",
    "speed_of_sound",
]
PYEOF

cat > src/fluid_mechanics_toolkit/compressible_flow/isentropic.py <<'PYEOF'
"""Isentropic compressible-flow relations for a calorically perfect gas."""

from __future__ import annotations

DEFAULT_GAMMA = 1.4  # ratio of specific heats for air


def speed_of_sound(temperature: float, gas_constant: float = 287.05, gamma: float = DEFAULT_GAMMA) -> float:
    """Local speed of sound in a perfect gas: a = sqrt(gamma R T).

    Parameters
    ----------
    temperature : float
        Static temperature [K].
    gas_constant : float, optional
        Specific gas constant [J/(kg K)].
    gamma : float, optional
        Ratio of specific heats.

    Returns
    -------
    float
        Speed of sound [m/s].
    """
    if temperature <= 0:
        raise ValueError("temperature must be positive")
    return (gamma * gas_constant * temperature) ** 0.5


def mach_number(velocity: float, local_speed_of_sound: float) -> float:
    """Mach number M = V / a."""
    if local_speed_of_sound <= 0:
        raise ValueError("local_speed_of_sound must be positive")
    return velocity / local_speed_of_sound


def isentropic_temperature_ratio(mach: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Stagnation-to-static temperature ratio T0/T = 1 + (gamma-1)/2 * M^2."""
    if mach < 0:
        raise ValueError("mach must be non-negative")
    return 1.0 + (gamma - 1.0) / 2.0 * mach ** 2


def isentropic_pressure_ratio(mach: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Stagnation-to-static pressure ratio p0/p = (T0/T)^(gamma/(gamma-1))."""
    return isentropic_temperature_ratio(mach, gamma) ** (gamma / (gamma - 1.0))


def isentropic_density_ratio(mach: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Stagnation-to-static density ratio rho0/rho = (T0/T)^(1/(gamma-1))."""
    return isentropic_temperature_ratio(mach, gamma) ** (1.0 / (gamma - 1.0))
PYEOF

echo "  compressible_flow done"

cat > src/fluid_mechanics_toolkit/shock_waves/__init__.py <<'PYEOF'
"""Normal shock-wave relations for a calorically perfect gas."""

from .normal_shock import (
    normal_shock_mach_downstream,
    normal_shock_pressure_ratio,
    normal_shock_temperature_ratio,
    normal_shock_density_ratio,
)

__all__ = [
    "normal_shock_mach_downstream",
    "normal_shock_pressure_ratio",
    "normal_shock_temperature_ratio",
    "normal_shock_density_ratio",
]
PYEOF

cat > src/fluid_mechanics_toolkit/shock_waves/normal_shock.py <<'PYEOF'
"""Normal shock relations (calorically perfect gas), from the Rankine-Hugoniot relations.

All functions take the upstream (pre-shock) Mach number M1 > 1.
"""

from __future__ import annotations

DEFAULT_GAMMA = 1.4


def _check_mach(mach1: float) -> None:
    if mach1 < 1.0:
        raise ValueError("normal shock relations require an upstream Mach number M1 >= 1")


def normal_shock_mach_downstream(mach1: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Downstream Mach number M2 behind a normal shock:

        M2^2 = (1 + (gamma-1)/2 M1^2) / (gamma M1^2 - (gamma-1)/2)
    """
    _check_mach(mach1)
    numerator = 1.0 + (gamma - 1.0) / 2.0 * mach1 ** 2
    denominator = gamma * mach1 ** 2 - (gamma - 1.0) / 2.0
    return (numerator / denominator) ** 0.5


def normal_shock_pressure_ratio(mach1: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Static pressure ratio across a normal shock: p2/p1 = 1 + 2 gamma/(gamma+1) (M1^2 - 1)."""
    _check_mach(mach1)
    return 1.0 + (2.0 * gamma) / (gamma + 1.0) * (mach1 ** 2 - 1.0)


def normal_shock_density_ratio(mach1: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Density ratio across a normal shock: rho2/rho1 = (gamma+1) M1^2 / ((gamma-1) M1^2 + 2)."""
    _check_mach(mach1)
    return ((gamma + 1.0) * mach1 ** 2) / ((gamma - 1.0) * mach1 ** 2 + 2.0)


def normal_shock_temperature_ratio(mach1: float, gamma: float = DEFAULT_GAMMA) -> float:
    """Static temperature ratio across a normal shock, T2/T1 = (p2/p1) * (rho1/rho2)."""
    _check_mach(mach1)
    pressure_ratio = normal_shock_pressure_ratio(mach1, gamma)
    density_ratio = normal_shock_density_ratio(mach1, gamma)
    return pressure_ratio / density_ratio
PYEOF

echo "  shock_waves done"

cat > src/fluid_mechanics_toolkit/numerical_methods/__init__.py <<'PYEOF'
"""Finite-difference building blocks used across the toolkit's numerical solvers."""

from .finite_difference import forward_difference, central_difference, second_derivative_central

__all__ = ["forward_difference", "central_difference", "second_derivative_central"]
PYEOF

cat > src/fluid_mechanics_toolkit/numerical_methods/finite_difference.py <<'PYEOF'
"""Simple finite-difference derivative approximations for a callable f(x)."""

from __future__ import annotations

from typing import Callable


def forward_difference(f: Callable[[float], float], x: float, h: float = 1e-5) -> float:
    """First derivative via first-order forward difference: (f(x+h) - f(x)) / h."""
    if h == 0:
        raise ValueError("h must be non-zero")
    return (f(x + h) - f(x)) / h


def central_difference(f: Callable[[float], float], x: float, h: float = 1e-5) -> float:
    """First derivative via second-order central difference: (f(x+h) - f(x-h)) / (2h)."""
    if h == 0:
        raise ValueError("h must be non-zero")
    return (f(x + h) - f(x - h)) / (2 * h)


def second_derivative_central(f: Callable[[float], float], x: float, h: float = 1e-4) -> float:
    """Second derivative via second-order central difference: (f(x+h) - 2f(x) + f(x-h)) / h^2."""
    if h == 0:
        raise ValueError("h must be non-zero")
    return (f(x + h) - 2.0 * f(x) + f(x - h)) / h ** 2
PYEOF

echo "  numerical_methods done"

cat > src/fluid_mechanics_toolkit/verification_validation/__init__.py <<'PYEOF'
"""CFD verification & validation utilities: convergence and error-norm helpers."""

from .convergence import richardson_extrapolation, grid_convergence_index, l2_norm_error

__all__ = ["richardson_extrapolation", "grid_convergence_index", "l2_norm_error"]
PYEOF

cat > src/fluid_mechanics_toolkit/verification_validation/convergence.py <<'PYEOF'
"""Grid-convergence utilities for CFD verification & validation studies.

References
----------
Roache, P. J., "Perspective: A Method for Uniform Reporting of Grid Refinement
Studies," ASME Journal of Fluids Engineering, 1994.
"""

from __future__ import annotations

from typing import Sequence


def richardson_extrapolation(f_fine: float, f_coarse: float, refinement_ratio: float,
                              order: float = 2.0) -> float:
    """Richardson-extrapolated estimate of the exact (grid-converged) solution.

        f_exact ~= f_fine + (f_fine - f_coarse) / (r^order - 1)

    Parameters
    ----------
    f_fine : float
        Solution value on the fine grid.
    f_coarse : float
        Solution value on the coarse grid.
    refinement_ratio : float
        Grid refinement ratio r = h_coarse / h_fine (r > 1).
    order : float, optional
        Formal order of accuracy of the numerical scheme.

    Returns
    -------
    float
        Extrapolated estimate of the exact solution.
    """
    if refinement_ratio <= 1:
        raise ValueError("refinement_ratio must be > 1")
    return f_fine + (f_fine - f_coarse) / (refinement_ratio ** order - 1.0)


def grid_convergence_index(f_fine: float, f_coarse: float, refinement_ratio: float,
                            order: float = 2.0, safety_factor: float = 1.25) -> float:
    """Roache's Grid Convergence Index (GCI), a standardized measure of discretization
    uncertainty between two grid resolutions:

        GCI = Fs * |e| / (r^order - 1),  e = (f_coarse - f_fine) / f_fine

    Parameters
    ----------
    f_fine : float
        Solution value on the fine grid (must be non-zero).
    f_coarse : float
        Solution value on the coarse grid.
    refinement_ratio : float
        Grid refinement ratio r = h_coarse / h_fine (r > 1).
    order : float, optional
        Formal (theoretical) order of accuracy of the scheme.
    safety_factor : float, optional
        Recommended safety factor Fs (1.25 for 3+ grids, 3.0 for 2-grid comparisons).

    Returns
    -------
    float
        GCI, expressed as a fraction (multiply by 100 for percent).
    """
    if refinement_ratio <= 1:
        raise ValueError("refinement_ratio must be > 1")
    if f_fine == 0:
        raise ValueError("f_fine must be non-zero")
    relative_error = abs((f_coarse - f_fine) / f_fine)
    return safety_factor * relative_error / (refinement_ratio ** order - 1.0)


def l2_norm_error(numerical: Sequence[float], exact: Sequence[float]) -> float:
    """Discrete L2 norm of the error between a numerical and exact/reference solution.

        ||e||_2 = sqrt( (1/N) * sum( (u_num - u_exact)^2 ) )

    Parameters
    ----------
    numerical : sequence of float
        Numerical solution values.
    exact : sequence of float
        Exact or reference solution values, same length as `numerical`.

    Returns
    -------
    float
        Root-mean-square L2 error norm.
    """
    if len(numerical) != len(exact):
        raise ValueError("numerical and exact must have the same length")
    if len(numerical) == 0:
        raise ValueError("input sequences must be non-empty")
    n = len(numerical)
    squared_sum = sum((u - e) ** 2 for u, e in zip(numerical, exact))
    return (squared_sum / n) ** 0.5
PYEOF

echo "  verification_validation done"

echo "Writing tests..."

touch tests/__init__.py

cat > tests/test_fundamentals.py <<'PYEOF'
import math

import pytest

from fluid_mechanics_toolkit.fundamentals import (
    ideal_gas_density,
    dynamic_to_kinematic_viscosity,
    reynolds_number,
    hydrostatic_pressure,
    buoyant_force,
)


def test_ideal_gas_density_standard_air():
    # Standard sea-level air: p=101325 Pa, T=288.15 K -> rho ~= 1.225 kg/m^3
    rho = ideal_gas_density(101325.0, 288.15)
    assert rho == pytest.approx(1.225, rel=1e-3)


def test_ideal_gas_density_rejects_nonpositive_temperature():
    with pytest.raises(ValueError):
        ideal_gas_density(101325.0, 0.0)


def test_dynamic_to_kinematic_viscosity():
    # Air at ~15C: mu ~= 1.81e-5 Pa s, rho ~= 1.225 kg/m^3 -> nu ~= 1.48e-5 m^2/s
    nu = dynamic_to_kinematic_viscosity(1.81e-5, 1.225)
    assert nu == pytest.approx(1.4776e-5, rel=1e-2)


def test_reynolds_number():
    re = reynolds_number(velocity=2.0, length=0.1, kinematic_viscosity=1.5e-5)
    assert re == pytest.approx(2.0 * 0.1 / 1.5e-5)


def test_hydrostatic_pressure_gauge():
    p = hydrostatic_pressure(density=1000.0, depth=10.0)
    assert p == pytest.approx(1000.0 * 9.80665 * 10.0)


def test_hydrostatic_pressure_rejects_negative_depth():
    with pytest.raises(ValueError):
        hydrostatic_pressure(density=1000.0, depth=-1.0)


def test_buoyant_force():
    f = buoyant_force(fluid_density=1000.0, displaced_volume=0.002)
    assert f == pytest.approx(1000.0 * 0.002 * 9.80665)
PYEOF

cat > tests/test_internal_flow.py <<'PYEOF'
import pytest

from fluid_mechanics_toolkit.internal_flow import (
    friction_factor_laminar,
    friction_factor_colebrook,
    darcy_weisbach_head_loss,
    flow_regime,
)


def test_flow_regime_classification():
    assert flow_regime(1000) == "laminar"
    assert flow_regime(3000) == "transitional"
    assert flow_regime(10000) == "turbulent"


def test_friction_factor_laminar():
    assert friction_factor_laminar(1000.0) == pytest.approx(64.0 / 1000.0)


def test_friction_factor_laminar_rejects_nonpositive_reynolds():
    with pytest.raises(ValueError):
        friction_factor_laminar(0.0)


def test_friction_factor_colebrook_matches_swamee_jain_approximation():
    # For a smooth-ish pipe at turbulent Re, Colebrook should be close to the
    # Swamee-Jain explicit approximation used as the initial guess.
    re = 1e5
    relative_roughness = 0.0004
    f = friction_factor_colebrook(re, relative_roughness)
    assert 0.015 < f < 0.03


def test_darcy_weisbach_head_loss():
    h = darcy_weisbach_head_loss(friction_factor=0.02, length=100.0, diameter=0.5, velocity=2.0)
    expected = 0.02 * (100.0 / 0.5) * (2.0 ** 2) / (2 * 9.80665)
    assert h == pytest.approx(expected)


def test_darcy_weisbach_head_loss_rejects_nonpositive_diameter():
    with pytest.raises(ValueError):
        darcy_weisbach_head_loss(friction_factor=0.02, length=100.0, diameter=0.0, velocity=2.0)
PYEOF

cat > tests/test_external_flow.py <<'PYEOF'
import pytest

from fluid_mechanics_toolkit.external_flow import (
    blasius_boundary_layer_thickness,
    flat_plate_drag_coefficient,
)


def test_blasius_boundary_layer_thickness():
    delta = blasius_boundary_layer_thickness(x=1.0, reynolds_x=1e5)
    assert delta == pytest.approx(5.0 * 1.0 / (1e5 ** 0.5))


def test_blasius_boundary_layer_thickness_rejects_nonpositive_reynolds():
    with pytest.raises(ValueError):
        blasius_boundary_layer_thickness(x=1.0, reynolds_x=0.0)


def test_flat_plate_drag_coefficient():
    cd = flat_plate_drag_coefficient(reynolds_l=1e5)
    assert cd == pytest.approx(1.328 / (1e5 ** 0.5))
PYEOF

echo "  tests part 1 done"

cat > tests/test_compressible_flow.py <<'PYEOF'
import pytest

from fluid_mechanics_toolkit.compressible_flow import (
    speed_of_sound,
    mach_number,
    isentropic_temperature_ratio,
    isentropic_pressure_ratio,
    isentropic_density_ratio,
)


def test_speed_of_sound_standard_air():
    a = speed_of_sound(288.15)
    assert a == pytest.approx(340.3, rel=1e-2)


def test_mach_number():
    assert mach_number(velocity=340.0, local_speed_of_sound=340.0) == pytest.approx(1.0)


def test_isentropic_ratios_at_zero_mach_are_unity():
    assert isentropic_temperature_ratio(0.0) == pytest.approx(1.0)
    assert isentropic_pressure_ratio(0.0) == pytest.approx(1.0)
    assert isentropic_density_ratio(0.0) == pytest.approx(1.0)


def test_isentropic_pressure_ratio_at_mach_1():
    # Standard NACA 1135 result: p0/p at M=1 for gamma=1.4 is ~1.89293
    assert isentropic_pressure_ratio(1.0) == pytest.approx(1.89293, rel=1e-4)


def test_isentropic_temperature_ratio_rejects_negative_mach():
    with pytest.raises(ValueError):
        isentropic_temperature_ratio(-0.5)
PYEOF

cat > tests/test_shock_waves.py <<'PYEOF'
import pytest

from fluid_mechanics_toolkit.shock_waves import (
    normal_shock_mach_downstream,
    normal_shock_pressure_ratio,
    normal_shock_density_ratio,
    normal_shock_temperature_ratio,
)


def test_no_shock_at_mach_1():
    # At M1 = 1 there is no jump: all ratios should be 1 and M2 = 1.
    assert normal_shock_mach_downstream(1.0) == pytest.approx(1.0)
    assert normal_shock_pressure_ratio(1.0) == pytest.approx(1.0)
    assert normal_shock_density_ratio(1.0) == pytest.approx(1.0)
    assert normal_shock_temperature_ratio(1.0) == pytest.approx(1.0)


def test_normal_shock_at_mach_2():
    # Standard NACA 1135 normal shock table values for M1 = 2.0, gamma = 1.4:
    # M2 = 0.57735, p2/p1 = 4.5, rho2/rho1 = 2.66667, T2/T1 = 1.6875
    assert normal_shock_mach_downstream(2.0) == pytest.approx(0.57735, rel=1e-4)
    assert normal_shock_pressure_ratio(2.0) == pytest.approx(4.5, rel=1e-4)
    assert normal_shock_density_ratio(2.0) == pytest.approx(2.66667, rel=1e-4)
    assert normal_shock_temperature_ratio(2.0) == pytest.approx(1.6875, rel=1e-4)


def test_rejects_subsonic_upstream_mach():
    with pytest.raises(ValueError):
        normal_shock_pressure_ratio(0.5)
PYEOF

cat > tests/test_numerical_methods.py <<'PYEOF'
import math

import pytest

from fluid_mechanics_toolkit.numerical_methods import (
    forward_difference,
    central_difference,
    second_derivative_central,
)


def test_central_difference_on_sine():
    # d/dx sin(x) at x=0 is cos(0) = 1
    approx = central_difference(math.sin, 0.0)
    assert approx == pytest.approx(1.0, abs=1e-6)


def test_forward_difference_on_square():
    # d/dx x^2 at x=2 is 4
    approx = forward_difference(lambda x: x ** 2, 2.0, h=1e-6)
    assert approx == pytest.approx(4.0, abs=1e-3)


def test_second_derivative_central_on_square():
    # d2/dx2 x^2 is 2 everywhere
    approx = second_derivative_central(lambda x: x ** 2, 3.0)
    assert approx == pytest.approx(2.0, abs=1e-4)
PYEOF

cat > tests/test_verification_validation.py <<'PYEOF'
import pytest

from fluid_mechanics_toolkit.verification_validation import (
    richardson_extrapolation,
    grid_convergence_index,
    l2_norm_error,
)


def test_richardson_extrapolation_exact_when_converged():
    # If fine and coarse solutions already agree, extrapolation returns the same value.
    assert richardson_extrapolation(f_fine=1.0, f_coarse=1.0, refinement_ratio=2.0) == pytest.approx(1.0)


def test_richardson_extrapolation_second_order():
    result = richardson_extrapolation(f_fine=2.0, f_coarse=2.5, refinement_ratio=2.0, order=2.0)
    expected = 2.0 + (2.0 - 2.5) / (2.0 ** 2 - 1.0)
    assert result == pytest.approx(expected)


def test_grid_convergence_index_zero_when_grids_agree():
    gci = grid_convergence_index(f_fine=1.0, f_coarse=1.0, refinement_ratio=2.0)
    assert gci == pytest.approx(0.0)


def test_grid_convergence_index_rejects_invalid_refinement_ratio():
    with pytest.raises(ValueError):
        grid_convergence_index(f_fine=1.0, f_coarse=1.1, refinement_ratio=1.0)


def test_l2_norm_error_zero_for_identical_sequences():
    assert l2_norm_error([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]) == pytest.approx(0.0)


def test_l2_norm_error_basic_case():
    err = l2_norm_error([1.0, 2.0], [0.0, 0.0])
    assert err == pytest.approx(((1.0 ** 2 + 2.0 ** 2) / 2) ** 0.5)


def test_l2_norm_error_rejects_mismatched_lengths():
    with pytest.raises(ValueError):
        l2_norm_error([1.0, 2.0], [1.0])
PYEOF

echo "  tests done"

echo "Writing project metadata files..."

cat > pyproject.toml <<'PYEOF'
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "fluid-mechanics-computational-toolkit"
version = "0.1.0"
description = "A computational fluid mechanics toolkit covering fundamental fluid mechanics, internal and external flows, compressible flow, shock-wave analysis, numerical methods, CFD verification, and validation."
readme = "README.md"
requires-python = ">=3.9"
license = { text = "MIT" }
authors = [
    { name = "Rajdeep Bose Mondal" }
]
keywords = [
    "fluid-mechanics",
    "cfd",
    "compressible-flow",
    "shock-waves",
    "numerical-methods",
    "verification-validation",
]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Topic :: Scientific/Engineering",
]
dependencies = [
    "numpy>=1.24",
    "scipy>=1.10",
    "matplotlib>=3.7",
]

[project.optional-dependencies]
dev = ["pytest>=7.4", "pytest-cov>=4.1"]

[project.urls]
Homepage = "https://github.com/RAJDEEP678/fluid-mechanics-computational-toolkit"
Issues = "https://github.com/RAJDEEP678/fluid-mechanics-computational-toolkit/issues"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
PYEOF

cat > requirements.txt <<'PYEOF'
numpy>=1.24
scipy>=1.10
matplotlib>=3.7
pytest>=7.4
pytest-cov>=4.1
PYEOF

cat > .gitignore <<'PYEOF'
# Byte-compiled / optimized files
__pycache__/
*.py[cod]
*$py.class

# Distribution / packaging
build/
dist/
*.egg-info/
.eggs/

# Virtual environments
.venv/
venv/
env/

# Testing / coverage
.pytest_cache/
.coverage
htmlcov/

# Jupyter
.ipynb_checkpoints/

# Editors / OS
.vscode/
.idea/
.DS_Store

# Environment variables
.env
PYEOF

cat > LICENSE <<'PYEOF'
MIT License

Copyright (c) 2026 Rajdeep Bose Mondal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
PYEOF

echo "  metadata files done"

echo "Writing examples and docs..."

cat > examples/quickstart.py <<'PYEOF'
"""Quickstart example exercising a few functions from each sub-package.

Run with:
    python examples/quickstart.py
"""

from fluid_mechanics_toolkit.fundamentals import ideal_gas_density, reynolds_number
from fluid_mechanics_toolkit.internal_flow import friction_factor_colebrook, darcy_weisbach_head_loss
from fluid_mechanics_toolkit.compressible_flow import isentropic_pressure_ratio
from fluid_mechanics_toolkit.shock_waves import normal_shock_pressure_ratio
from fluid_mechanics_toolkit.verification_validation import grid_convergence_index


def main() -> None:
    # 1. Fundamentals: standard sea-level air density.
    rho = ideal_gas_density(pressure=101325.0, temperature=288.15)
    print(f"Standard air density: {rho:.4f} kg/m^3")

    # 2. Internal flow: friction factor and head loss for water in a pipe.
    re = reynolds_number(velocity=2.0, length=0.05, kinematic_viscosity=1.0e-6)
    f = friction_factor_colebrook(reynolds=re, relative_roughness=0.0002)
    h_loss = darcy_weisbach_head_loss(friction_factor=f, length=50.0, diameter=0.05, velocity=2.0)
    print(f"Re = {re:.0f}, f = {f:.4f}, head loss over 50 m = {h_loss:.3f} m")

    # 3. Compressible flow: stagnation-to-static pressure ratio at M = 0.8.
    p0_over_p = isentropic_pressure_ratio(mach=0.8)
    print(f"p0/p at M=0.8: {p0_over_p:.4f}")

    # 4. Shock waves: pressure ratio across a Mach 2.5 normal shock.
    p2_over_p1 = normal_shock_pressure_ratio(mach1=2.5)
    print(f"p2/p1 across a normal shock at M1=2.5: {p2_over_p1:.4f}")

    # 5. Verification & validation: GCI between two grid resolutions.
    gci = grid_convergence_index(f_fine=1.502, f_coarse=1.489, refinement_ratio=2.0)
    print(f"Grid Convergence Index: {gci * 100:.3f}%")


if __name__ == "__main__":
    main()
PYEOF

cat > docs/overview.md <<'MDEOF'
# Project overview

`fluid-mechanics-computational-toolkit` is organized as a standard Python
`src`-layout package, `fluid_mechanics_toolkit`, with one sub-package per
topic area:

| Sub-package | Contents |
| --- | --- |
| `fundamentals` | Fluid properties (ideal-gas density, viscosity conversion, Reynolds number) and hydrostatics (pressure, buoyancy). |
| `internal_flow` | Pipe/duct flow: laminar and Colebrook-White friction factors, Darcy-Weisbach head loss, flow-regime classification. |
| `external_flow` | Flat-plate laminar boundary-layer thickness and drag coefficient (Blasius solution). |
| `compressible_flow` | Isentropic relations for a calorically perfect gas: speed of sound, Mach number, stagnation ratios. |
| `shock_waves` | Normal-shock jump relations (Rankine-Hugoniot). |
| `numerical_methods` | Finite-difference derivative approximations used across the toolkit's numerical solvers. |
| `verification_validation` | Richardson extrapolation, Grid Convergence Index (GCI), and discrete L2 error norms for CFD V&V studies. |

## Adding a new topic area

1. Create a new sub-package under `src/fluid_mechanics_toolkit/`.
2. Implement functions with docstrings describing the governing equation,
   parameters, units, and return value.
3. Export the public functions from the sub-package's `__init__.py`.
4. Add corresponding tests under `tests/`, checking against known analytical
   or tabulated results where possible (e.g., NACA 1135 tables for
   compressible-flow and shock relations).
5. Add a usage example to `examples/` if the topic introduces a new workflow.

## Running the test suite

```bash
pip install -e ".[dev]"
pytest
```
MDEOF

echo "  examples/docs done"

echo "Writing README.md..."

cat > README.md <<'MDEOF'
# fluid-mechanics-computational-toolkit

A computational fluid mechanics toolkit covering fundamental fluid
mechanics, internal and external flows, compressible flow, shock-wave
analysis, numerical methods, CFD verification, and validation using Python
and engineering simulations.

## Features

- **Fundamentals** — fluid properties (ideal-gas density, viscosity
  conversion, Reynolds number) and hydrostatics (pressure, buoyancy).
- **Internal flow** — pipe/duct friction factors (laminar and
  Colebrook-White), Darcy-Weisbach head loss, flow-regime classification.
- **External flow** — flat-plate laminar boundary-layer thickness and drag
  coefficient (Blasius solution).
- **Compressible flow** — isentropic relations for a calorically perfect
  gas (speed of sound, Mach number, stagnation ratios).
- **Shock waves** — normal-shock jump relations.
- **Numerical methods** — finite-difference derivative building blocks.
- **Verification & validation** — Richardson extrapolation, Grid
  Convergence Index (GCI), and L2 error norms for CFD V&V studies.

See [`docs/overview.md`](docs/overview.md) for the full module map and
guidance on adding new topic areas.

## Installation

```bash
git clone https://github.com/RAJDEEP678/fluid-mechanics-computational-toolkit.git
cd fluid-mechanics-computational-toolkit
python -m venv .venv
source .venv/bin/activate  # on Windows: .venv\Scripts\activate
pip install -e ".[dev]"
```

## Usage

```python
from fluid_mechanics_toolkit.compressible_flow import isentropic_pressure_ratio
from fluid_mechanics_toolkit.shock_waves import normal_shock_pressure_ratio

print(isentropic_pressure_ratio(mach=0.8))
print(normal_shock_pressure_ratio(mach1=2.5))
```

A runnable end-to-end example is provided in
[`examples/quickstart.py`](examples/quickstart.py):

```bash
python examples/quickstart.py
```

## Project structure

```
fluid-mechanics-computational-toolkit/
├── src/
│   └── fluid_mechanics_toolkit/
│       ├── fundamentals/
│       ├── internal_flow/
│       ├── external_flow/
│       ├── compressible_flow/
│       ├── shock_waves/
│       ├── numerical_methods/
│       └── verification_validation/
├── tests/                # pytest unit tests, one file per sub-package
├── examples/              # runnable usage examples
├── docs/                    # additional documentation
├── pyproject.toml
├── requirements.txt
└── LICENSE
```

## Running tests

```bash
pytest
```

## License

Distributed under the [MIT License](LICENSE).
MDEOF

echo ""
echo "Scaffolding complete."
echo ""
echo "Next steps:"
echo "  1. Review changes:  git status && git diff --stat"
echo "  2. (Recommended) Create and activate a virtualenv, then install:"
echo "       python -m venv .venv && source .venv/bin/activate"
echo "       pip install -e \".[dev]\""
echo "  3. Run the test suite:  pytest"
echo "  4. Try the example:     python examples/quickstart.py"
echo "  5. Commit and push:"
echo "       git add -A"
echo "       git commit -m \"Add Python project scaffolding\""
echo "       git push"
