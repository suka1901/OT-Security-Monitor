function risk = ot_risk()
%OT_RISK Likelihood x consequence risk model (1..5) for the demo scenarios.
risk.scenarios   = ["Sensor spoofing","Command injection","Replay attack", ...
                    "Ransomware-like OT disruption","Supply-chain / vendor compromise"];
risk.likelihood  = [3 2 3 4 3];
risk.consequence = [4 5 3 5 4];
risk.csf         = ["DE.AE","RS.MA","DE.CM","RC.RP","GV.SC"];
risk.score       = risk.likelihood .* risk.consequence;
end
