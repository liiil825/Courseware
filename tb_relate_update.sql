BEGIN
    declare @temp table (id int, relate_id int, title nvarchar(100), lessonId int, classnum tinyint, ishdv bit, relateNum int, lessonyear smallint, media varchar(50), hdvrnd int, audiornd int, svideornd int, hvideornd int, isdemo bit, isfree bit, isexam bit, test bit, teacherId int, playerver smallint, startdate datetime, status tinyint, isshow bit, reStatus tinyint, mp4status tinyint, mp4restatus tinyint)
	declare @temp2 table(relate_id int, relateNum int, lessonyear smallint,hdvrnd int, audiornd int, svideornd int, hvideornd int)
    declare @id int, @relate_id int, @title nvarchar(50), @lessonId int, @classnum tinyint, @ishdv bit, @relateNum int, @relateNum2 int, @relateType int, @contentType int, @teacherId int, @lessonyear smallint, @lessonyear2 smallint, @media varchar(50), @hdvRnd int, @hdvRnd2 int, @audioRnd int, @audioRnd2 int, @svideornd int, @svideornd2 int, @hvideornd int, @hvideornd2 int, @playerver smallint, @status tinyint
    declare @relateId int, @attchmentId int

    insert into @temp
    select r.id, i.relate_id, i.title, i.lesson_id, i.classnum, ishdv, relate, lessonyear, media, hdvrnd, audiornd, svideornd, hvideornd, isdemo, is_free, isexam, test, teacher_id, playerver, i.startdate, i.status, i.isshow, i.reStatus, i.mp4status, i.mp4restatus
    from inserted i, Courseware.dbo.tb_Relate r,Courseware.dbo.tb_Relate_Product_Mapping m where i.class_id = m.productId and i.lessonyear = m.year and m.productsource = 1 and m.producttype=1 and m.type=1 and r.id=m.relateid
    insert into @temp2
    select relate_id, relate, lessonyear, hdvrnd, audiornd, svideornd, hvideornd from deleted
END

while exists(select id from @temp)
    begin
        select @id = id, @relate_id = relate_id, @title = title, @lessonId = lessonId, @classnum = classnum, 
        @relateType = case when isdemo=1 and isfree=1 then 4 when isdemo=1 and isfree<>1 then 3 when isfree = 1 and isdemo<>1 then 2 else 1 end, 
        @contentType = case isexam when 1 then 3 else (case test when 2 then 2 else 1 end) end, 
        @ishdv = ishdv,@relateNum = relatenum,@lessonyear = lessonyear,@media = media,@hdvrnd = hdvrnd,@audiornd = audiornd,@svideornd = svideornd,@hvideornd=hvideornd,@playerver = playerver, @teacherId = teacherId, 
        --@status = case when status = 0 then 0 
                       --else (case when isshow = 0 then (case when ((status < reStatus) or (mp4status < mp4restatus)) then 2 else 1)
                             --else (case when ((status < reStatus) or (mp4status < mp4restatus)) then 4 else 3)) end from @temp
        @status = case when [status] = 0 then 0 
                       when [status] <> 0 and isshow = 0 and [status] < reStatus or mp4status < mp4restatus then 2
                       when [status] <> 0 and isshow = 0 and NOT([status] < reStatus or mp4status < mp4restatus) then 1
                       when [status] <> 0 and isshow = 1 and [status] < reStatus or mp4status < mp4restatus then 4
                       when [status] <> 0 and isshow = 1 and NOT([status] < reStatus or mp4status < mp4restatus) then 3
                                end from @temp
        
        delete from @temp where relate_id = @relate_id
        select @relateNum2 = relateNum, @lessonyear2 = lessonyear, @hdvRnd2 = hdvRnd, @audioRnd2 = audioRnd, @svideornd2 = svideornd, @hvideornd2 = hvideornd from @temp2 where relate_id = @relate_id
        delete from @temp2 where relate_id = @relate_id
        --更新讲座信息
        update Courseware.dbo.tb_Relate set title = @title, [type] = @relateType, contentType=@contentType, [index] = @relateNum, updatedDate = getdate(), teacherId = @teacherId, [status] = @status where id = @id

        --更新附件信息
		declare @videoPath varchar(256), @audioPath varchar(256), @docPath varchar(256), @htmlPath varchar(256), @tempPath varchar(256), @rnd int

        set @rnd = @audiornd
        if @ishdv = 1
            set @rnd = 0
        if @ishdv = 1 and @hdvrnd>9999999
            set @rnd = @hdvrnd

        set @tempPath = @lessonId + '/' +(select case @ishdv when 1 then '' else 'a' end)+ @lessonId + '-' + @classnum + '-' + @relateNum + '-' + @lessonYear + '-'
        
        --更新音频
        if charIndex(@media,',1,') > 0 and (@relateNum <> @relateNum2 or @hdvrnd <> @hdvrnd2 or @lessonyear <> @lessonyear2)
        begin
        select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 1
        set @audioPath = 'mp3/' + @tempPath + @rnd + '.mp3'
        update Courseware.dbo.tb_Attchment set path = @audioPath where id = @attchmentId
        end

        --更新视频和讲义
        if @ishdv = 1 and (@relateNum <> @relateNum2 or @lessonyear <> @lessonyear2 or @hdvrnd <> @hdvrnd2)
        begin
            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 5
            set @videoPath = 'flv/' + @tempPath + @hdvrnd + '.flv'
            update Courseware.dbo.tb_Attchment set path = @videoPath where id=@attchmentId
                    
            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 6
            set @videoPath = 'hlv/m3u8/' + @tempPath + @hdvrnd + '_high.m3u8'
            update Courseware.dbo.tb_Attchment set path = @videoPath where id=@attchmentId

            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 7
            set @videoPath = 'hlv/m3u8/' + @tempPath + @hdvrnd + '_low.m3u8'
            update Courseware.dbo.tb_Attchment set path = @videoPath where id=@attchmentId
                    
            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 11
            set @docPath = 'mp3/' + @tempPath + @rnd + '.pdf'
            update Courseware.dbo.tb_Attchment set path = @docPath where id=@attchmentId
        end
        else
        begin
            if @relateNum <> @relateNum2 or @lessonyear <> @lessonyear2 or @svideornd <> @svideornd2 or @hvideornd <> @hvideornd2
            begin
                if charIndex(@media,',3,') > 0
                    set @videoPath = 'mp4/' + replace(@tempPath, @lessonId+'/a', @lessonId+'/s')+ @svideornd + '.mp4'
                if charIndex(@media,',4,') > 0
                    set @videoPath = 'mp4/' + replace(@tempPath, @lessonId+'/a', @lessonId+'/h')+ @hvideornd + '.mp4'

                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 3
                update Courseware.dbo.tb_Attchment set path = @videoPath where id=@attchmentId
                    
                set @docPath = 'mp3/' + @tempPath + @rnd + '.doc'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 10
                update Courseware.dbo.tb_Attchment set path = @docPath where id=@attchmentId
            end
        end
    end
