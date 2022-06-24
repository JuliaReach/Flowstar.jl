using Flowstar, TaylorModels

timestep = 0.02 # Fixed
# timestep = 0.01..0.05 # Variable 

finaltime = 3.0

# tmorder = FixedTMOrder(4)
tmorder = AdaptiveTMOrder(4,6)

states = "x,y"
params = nothing
eom = " x' = 1.5*x - x*y\n y' = -3*y + x*y"
dom = IntervalBox(4.8..5.2, 1.8..2.2)

lv_sett = FlowstarSetting(timestep, finaltime, tmorder, states; rem_est=0.0001, precond=QRPreconditioner(), cutoff = 1e-20, precision=53)
crm = ContinuousReachModel(states, params, lv_sett, PolyODEScheme2(), eom, IntervalBox(4.8..5.2, 1.8..2.2))
print(string(crm))

fcs = FlowstarContinuousSolution(crm)
domain(fcs)

rs = flowpipe(fcs)
