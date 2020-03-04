select ic.user_id,
       ic.creation_time,
       ic.id,
       ic.instance_type,
       ic.image_id,
       ic.security_group_id,
       ic.instance_storage,
       ins.id,
       ins.status,
       ins.time
from instance_created ic
         left join instance_status ins on ic.id = ins.id