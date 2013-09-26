BEGIN
    declare @temp table (id int)
    declare @id int

    insert into @temp
    select r.Id
    from deleted d, Courseware.dbo.tb_Relate r,Courseware.dbo.tb_Relate_Product_Mapping m where d.class_id = m.productId and d.lessonyear = m.year and m.productsource = 1 and m.producttype = 1 and m.type = 1 and r.id = m.relateid and r.[index] = d.[index]
  
    while exists(select id from @temp)
    begin
        select @id = id from @temp
        delete @temp where id = @id
        ------------------------------------------------讲Relate表状态调正为删除------------------------------------------------
        update Courseware.dob.tb_Relate set [Status] = 0 where Id = @id
        ------------------------------------------------插入操作记录------------------------------------------------
        insert into CoursewareWorkflow.dbo.tb_Operation_Record(TargetId, TargetType, CreatedDate, [Type], Content, [Comment])
        select 2, @id, getdate(), 5, '删除Relate表信息', ''
    end
END

