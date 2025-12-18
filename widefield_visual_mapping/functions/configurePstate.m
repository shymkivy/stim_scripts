function Pstate = configurePstate(modID)

switch modID
    
    case 'PG'
        
        Pstate = configPstate_perGrater;
        
    case 'FG'
      
        Pstate = configPstate_flashGrater;
        
    case 'RD'
        
        Pstate = configPstate_Rain;
        
    case 'FN'
        
        Pstate = configPstate_Noise;
        
    case 'MP'
        
        Pstate = configPstate_Mapper;
        
     case 'CM'
        
        Pstate = configPstate_cohMotion;

        
end

