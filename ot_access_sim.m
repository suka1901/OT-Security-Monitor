function alog = ot_access_sim(acfg)
%OT_ACCESS_SIM Generate synthetic OT/IT access logs (normal behaviour).
%  Each row = one access event with WHO/WHEN/WHERE/WHAT/HOW MUCH. The OT
%  process values are untouched and look perfectly normal; the security
%  signal lives entirely in the access pattern. Base MATLAB only.
if nargin < 1, acfg = ot_access_config(); end
rng(acfg.seed);
U = acfg.users; nU = numel(U);

time = datetime.empty(0,1);
user = strings(0,1); role = strings(0,1); loc = strings(0,1);
resource = strings(0,1); action = strings(0,1); vol = zeros(0,1);

for d = 0:acfg.days-1
    dayStart = acfg.t0 + days(d);
    isWeekend = weekday(dayStart) == 1 || weekday(dayStart) == 7;
    for u = 1:nU
        s = U(u);
        n = s.nday;
        % vendor only works in a booked window on weekdays 2 & 5
        if s.role == "Leverantor"
            if ~(d==2 || d==5), continue; end
        end
        if isWeekend && (s.role=="Ingenjor"||s.role=="Ekonomi"||s.role=="IT-admin")
            n = max(0, round(n*0.2));   % light weekend activity
        end
        for e = 1:n
            hr = s.h0 + (s.h1-s.h0)*rand;            % within active hours
            t  = dayStart + hours(hr) + minutes(60*rand);
            r  = s.res(randi(numel(s.res)));         % a resource for the role
            % action: mostly read; engineers occasionally config; small export
            a  = "read";
            if (s.role=="Ingenjor"||s.role=="Leverantor") && rand<0.12, a="config"; end
            if rand<0.06, a="export"; end
            v  = max(0.2, s.vmean*(0.4+0.9*rand));   % typical data volume [MB]
            if a=="export", v = v*(1.5+rand); end
            time(end+1,1)=t; user(end+1,1)=s.user; role(end+1,1)=s.role; %#ok<AGROW>
            loc(end+1,1)=s.loc; resource(end+1,1)=r; action(end+1,1)=a; vol(end+1,1)=v; %#ok<AGROW>
        end
    end
end

alog = table(time,user,role,loc,resource,action,vol);
alog = sortrows(alog,'time');
alog.label    = zeros(height(alog),1);     % 0 = normal
alog.typeName = repmat("Normal",height(alog),1);
alog.Properties.UserData = acfg;
end
