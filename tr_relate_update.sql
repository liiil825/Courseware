BEGIN
    -----------------------------@temp表保存插入的信息-----------------------------
    declare @temp table (relateId int, title nvarchar(100), lessonId int, classnum tinyint, classId int, ishdv bit, relateNum int, relateIndex int, lessonyear smallint, media varchar(50), hdvrnd int, audiornd int, svideornd int, hvideornd int, isdemo bit, isfree bit, isexam bit, test bit, teacherId int, playerver smallint, startdate datetime, status tinyint, isshow bit, reStatus tinyint, mp4status tinyint, mp4restatus tinyint)

    -----------------------------@temp2表保存删除的信息-----------------------------
    declare @temp2 table(id int, relateId int, relateNum int, relateIndex int, lessonId int, classnum tinyint, classId int, ishdv bit, lessonyear smallint, media varchar(50), playerver smallint, hdvrnd int, audiornd int, svideornd int, hvideornd int)

    declare @id int, @relateId int, @title nvarchar(50), @lessonId int, @lessonId2 int, @classNum tinyint, @classNum2 tinyint, @classId int, @classId2 int, @ishdv bit, @ishdv2 bit, @relateNum int, @relateNum2 int, @relateIndex int, @relateIndex2 int, @relateType int, @contentType int, @teacherId int, @lessonyear smallint, @lessonyear2 smallint, @media varchar(50), @media2 varchar(50), @hdvRnd int, @hdvRnd2 int, @audioRnd int, @audioRnd2 int, @svideornd int, @svideornd2 int, @hvideornd int, @hvideornd2 int, @playerver smallint, @playerver2 smallint, @status tinyint, @startDate datetime
    declare @attchmentId int

    insert into @temp
    select relate_id, title, lesson_id, classnum, class_id, ishdv, relate, [index], lessonyear, media, hdvrnd, audiornd, svideornd, hvideornd, isdemo, is_free, isexam, test, teacher_id, playerver, i.startdate, i.status, i.isshow, i.reStatus, i.mp4status, i.mp4restatus
    from inserted i 
    insert into @temp2
    select r.id, d.relate_id, d.relate, d.[index], d.lesson_id, d.classnum, d.class_id, d.ishdv, d.lessonyear, d.media, d.playerver, d.hdvrnd, d.audiornd, d.svideornd, d.hvideornd from deleted d, Courseware.dbo.tb_Relate r, Courseware.dbo.tb_Relate_Product_Mapping m where d.class_id = m.productId and d.lessonyear = m.year and m.productsource = 1 and m.producttype = 1 and m.[type] = 1 and d.relate_id = m.relateid and r.[index] = d.[index]

while exists(select relateId from @temp)
    begin
        ----------------------------------------查询@temp表字段赋予临时变量, 然后删除记录----------------------------------------
        select @relateId = relateId, @title = title, @lessonId = lessonId, @classnum = classnum, @classId = classId,
        @relateType = case when isdemo = 1 and isfree = 1 then 4 when isdemo = 1 and isfree <> 1 then 3 when isfree = 1 and isdemo <> 1 then 2 else 1 end,
        @contentType = case isexam when 1 then 3 else (case test when 2 then 2 else 1 end) end,
        @ishdv = ishdv, @relateNum = relatenum, @relateIndex = case when relateIndex > 0 then relateIndex else relateNum end, @lessonyear = lessonyear, @media = media, @hdvrnd = hdvrnd, @audiornd = audiornd, @svideornd = svideornd, @hvideornd=hvideornd, @playerver = playerver, @teacherId = teacherId, @startDate = startdate,
        --@status = case when status = 0 then 0
                       --else (case when isshow = 0 then (case when ((status < reStatus) or (mp4status < mp4restatus)) then 2 else 1)
                             --else (case when ((status < reStatus) or (mp4status < mp4restatus)) then 4 else 3)) end from @temp
        @status = case when [status] = 0 then 0
                       when [status] <> 0 and isshow = 0 and [status] < reStatus or mp4status < mp4restatus then 2
                       when [status] <> 0 and isshow = 0 and NOT([status] < reStatus or mp4status < mp4restatus) then 1
                       when [status] <> 0 and isshow = 1 and [status] < reStatus or mp4status < mp4restatus then 4
                       when [status] <> 0 and isshow = 1 and NOT([status] < reStatus or mp4status < mp4restatus) then 3
                                end from @temp
        delete from @temp where relateId = @relateId

        ----------------------------------------查询@temp2表字段赋予临时变量, 然后删除记录----------------------------------------
        select @id = id, @relateNum2 = relateNum, @relateIndex2 = case when relateIndex > 0 then relateIndex else relateNum end, @lessonId2 = lessonId, @classNum2 = classnum, @classId2 = classId, @ishdv2 = ishdv, @lessonyear2 = lessonyear, @media2 = media, @playerver2 = playerver, @hdvRnd2 = hdvRnd, @audioRnd2 = audioRnd, @svideornd2 = svideornd, @hvideornd2 = hvideornd from @temp2 where relateId = @relateId
        delete from @temp2 where relateId = @relateId

        ------------------------------------------------更新讲座信息------------------------------------------------
        update Courseware.dbo.tb_Relate set title = @title, [type] = @relateType, contentType = @contentType, [index] = @relateIndex, updatedDate = getdate(), teacherId = @teacherId, [status] = @status, StartDate = @startDate where id = @id

        ------------------------------------------------插入操作记录------------------------------------------------
        insert into CoursewareWorkflow.dbo.tb_Operation_Record(TargetId, TargetType, CreatedDate, [Type], Content, [Comment])
        select @relateId, 2, getdate(), 5, '', ''

        ------------------------------------------------开始更新附件信息------------------------------------------------
				declare @videoPath varchar(256), @audioPath varchar(256), @docPath varchar(256), @htmlPath varchar(256), @tempPath varchar(256), @rnd int

        set @rnd = @audiornd
        if @ishdv = 1
            set @rnd = 0
        if @ishdv = 1 and @hdvrnd > 9999999
            set @rnd = @hdvrnd

        set @tempPath = cast(@lessonId as varchar(25)) + '/' +(select case cast(@ishdv as varchar(25)) when 1 then '' else 'a' end)+ cast(@lessonId as varchar(6)) + '-' + cast(@classnum as varchar(6)) + '-' + cast(@relateNum as varchar(25)) + '-' + cast(@lessonYear as varchar(4)) + '-'

        ------------------------------------------------更新Html文件附件------------------------------------------------
        if @lessonId <> @lessonId2 or @classNum <> @classNum2 or @lessonyear <> @lessonyear2
        begin
            set @htmlPath = '/sound/upCourseaware/' + cast(@lessonId as varchar(25)) + '/' + cast(@lessonyear as varchar(25)) + '-' + cast(@classId as varchar(25)) + '-' + cast(@classNum as varchar(25)) + '-' + cast(@id as varchar(25)) + '.html'
            insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
            values (12, 'text/html', @htmlPath, 1, 0, @playerver, getdate(), getdate())
            insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
            values (@relateId, @@identity, 0, getdate())
        end

        ------------------------------------------------更新音频文件附件------------------------------------------------
        set @audioPath = 'mp3/' + @tempPath + cast(@rnd as varchar(25)) + '.mp3'
        --如果删除时也有音频, 并且组成文件名的参数有一个不同或者版本信息不同就更新
        if charIndex(@media,',1,') > 0 and charIndex(@media2, ',1,') > 0 and (@lessonId <> @lessonId2 or @classNum <> @classNum2 or @relateNum <> @relateNum2 or @audiornd <> @audiornd2 or @lessonyear <> @lessonyear2 or @playerver <> @playerver2)
        begin
            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 1
            update Courseware.dbo.tb_Attchment set path = @audioPath, version = @playerver where id = @attchmentId
        end

        --如果原来没有音频, 现在有音频则添加一天音频附件
        if charIndex(@media, ',1,') > 0 and charIndex(@media2, ',1,') <= 0
        begin
            insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
            values (1, 'audio/mp3', @audioPath, 1, 0, @playerver, getdate(), getdate())
            insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
            values (@relateId, @@identity, 0, getdate())
        end

        ------------------------------------------------更新高清视频文件附件和讲义------------------------------------------------
        --如果删除记录和插入记录的ishdv都为1则可能需要修改记录
        if @ishdv = 1 and @ishdv2 = 1
        begin
            if @lessonId <> @lessonId2 or @classNum <> @classNum2 or @relateNum <> @relateNum2 or @lessonyear <> @lessonyear2 or @hdvrnd <> @hdvrnd2 or @playerver <> @playerver2
            begin
                -----------------更新高清flv附件-----------------
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 5
                set @videoPath = 'flv/' + @tempPath + cast(@hdvrnd as varchar(25)) + '.flv'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId
                        
                -----------------更新高清high.m3u8附件-----------------
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 6
                set @videoPath = 'hlv/m3u8/' + @tempPath + cast(@hdvrnd as varchar(25)) + '_high.m3u8'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                -----------------更新高清low.m3u8附件-----------------
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 7
                set @videoPath = 'hlv/m3u8/' + @tempPath + cast(@hdvrnd as varchar(25)) + '_low.m3u8'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                -----------------更新Edu4附件-----------------
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 21
                set @videoPath = cast(@lessonId as varchar(25)) + '/' + cast(@lessonId as varchar(25)) + '-' + cast(@classNum as varchar(25)) + '-' + cast(@relateNum as varchar(25)) + '-' + cast(@lessonYear as varchar(25)) + cast(@hdvrnd as varchar(25)) + '.edu4'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                -----------------更新pdf附件-----------------
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 11
                set @docPath = 'mp3/' + @tempPath + cast(@rnd as varchar(25)) + '.pdf'
                update Courseware.dbo.tb_Attchment set path = @docPath, version = @playerver where id = @attchmentId
            end
        end
        --如果删除记录里ishdv=0插入记录ishdv=1则直接添加记录
        else if @ishdv = 1 and @ishdv2 = 0
            begin
						-----------------插入高清flv附件-----------------
						set @videoPath = 'flv/' + @tempPath + cast(@hdvrnd as varchar(25)) + '.flv'
						insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
						values (5, 'video/x-flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
						insert into Courseware.dbo.tb_Relation_Mapping(relateId,attachmentId,partId,createdDate)
						values (@relateId, @@identity, 0, getdate())
				
						-----------------插入高清high.m3u8附件-----------------
						set @videoPath = 'hlv/m3u8/' + @tempPath + cast(@hdvrnd as varchar(25)) + '_high.m3u8'
						insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
						values (6, 'application/x-mpegurl', @videoPath, 1, 0, @playerver, getdate(), getdate())
						insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
						values (@relateId, @@identity, 0, getdate())

						-----------------插入高清low.m3u8附件-----------------
						set @videoPath = 'hlv/m3u8/' + @tempPath + cast(@hdvrnd as varchar(25)) + '_low.m3u8'
						insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
						values (7, 'application/x-mpegurl', @videoPath, 1, 0, @playerver, getdate(), getdate())
						insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
						values (@relateId, @@identity, 0, getdate())
				
						-----------------插入Edu4附件-----------------
						set @videoPath = cast(@lessonId as varchar(25)) + '/' + cast(@lessonId as varchar(25)) + '-' + cast(@classNum as varchar(25)) + '-' + cast(@relateNum as varchar(25)) + '-' + cast(@lessonYear as varchar(25)) + cast(@hdvrnd as varchar(25)) + '.edu4'
						insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
						values (21, 'application/x-edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
						insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
						values (@relateId, @@identity, 0, getdate())
            end
						else if @ishdv = 0 and @ishdv2 = 0
						begin
            ------------------------------------------更新宽屏视频附件------------------------------------------
            if charIndex(@media, ',3,') > 0 and charIndex(@media2, ',3,') > 0 and (@svideornd <> @svideornd2 or @lessonId <> @lessonId2 or @classNum <> @classNum2 or @relateNum <> @relateNum2 or @lessonyear <> @lessonyear2 or @playerver <> @playerver2)
            begin
                ---------------------更新宽屏mp4文件---------------------
                set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.mp4'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 3 and a.mimeType = 'video/mp4'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                ---------------------更新宽屏flv文件---------------------
                set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.flv'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 3 and a.mimeType = 'video/flv'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                ---------------------更新宽屏Edu4文件---------------------
                set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.edu4'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 21
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId
            end
            ------------------------------------------插入宽屏视频附件------------------------------------------
            --如果删除数据里不包含宽屏, 但插入的数据包含则宽屏视频附件全为插入操作
            else if charIndex(@media, ',3,') > 0 and charIndex(@media2, ',3,') <= 0
            begin
                ---------------------------宽屏mp4附件---------------------------
                set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.mp4'
                insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                values (3, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())

                ---------------------------宽屏flv附件---------------------------
                set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.flv'
                insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                values (3, 'video/flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())

                ---------------------------宽屏edu4附件---------------------------
                set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.edu4'
                insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())
            end

            ------------------------------------------更新清晰屏视频附件------------------------------------------
            else if charIndex(@media, ',4,') > 0 and charIndex(@media2, ',4,') > 0 and (@hvideornd <> @hvideornd2 or @lessonId <> @lessonId2 or @classNum <> @classNum2 or @relateNum <> @relateNum2 or @lessonyear <> @lessonyear2 or @playerver <> @playerver2)
            begin
                ---------------------更新清晰mp4文件---------------------
                set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.mp4'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 4 and a.mimeType = 'video/mp4'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                ---------------------更新清晰屏flv文件---------------------
                set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.flv'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 4 and a.mimeType = 'video/flv'
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId

                ---------------------更新清晰屏Edu4文件---------------------
                set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.edu4'
                select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 21
                update Courseware.dbo.tb_Attchment set path = @videoPath, version = @playerver where id = @attchmentId
            end
            ------------------------------------------插入清晰屏视频附件------------------------------------------
            else if charIndex(@media, ',4,') > 0 and charIndex(@media2, ',4,') <= 0
            begin
                ---------------------------插入清晰mp4附件---------------------------
                set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.mp4'
                insert into Courseware.dbo.tb_Attachment(type,mimeType,path,status,activatedCount,version,updatedDate,createdDate)
                values (4, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())

                ---------------------------插入清晰flv附件---------------------------
                set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.flv'
                insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                values (4, 'video/flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())

                ---------------------------插入清晰edu4附件---------------------------
                set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.edu4'
                insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                values (@relateId, @@identity, 0, getdate())
            end

            set @docPath = 'mp3/' + @tempPath + cast(@rnd as varchar(25)) + '.doc'
            select @attchmentId = attchmentId from Courseware.dbo.tb_Relation_Mapping m, Courseware.dbo.tb_Attchment a where m.relatId = @id and a.type = 10
            update Courseware.dbo.tb_Attchment set path = @docPath where id=@attchmentId
        end
        --如果插入数据ishdv=0并且删除数据ishdv2=1那么就讲普通屏和清晰屏记录全用插入
        else if @ishdv = 0 and @ishdv2 = 1
        begin
            ----------------宽屏----------------
            if charIndex(@media, ',3,') > 0
                begin
                    ---------------------------宽屏mp4附件---------------------------
                    set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.mp4'
                    insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                    values (3, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())

                    ---------------------------宽屏flv附件---------------------------
                    set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.flv'
                    insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                    values (3, 'video/flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())

                    ---------------------------宽屏edu4附件---------------------------
                    set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/s') + cast(@svideornd as varchar(25)) + '.edu4'
                    insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                    values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())
                end
            ----------------清晰屏----------------
            if charIndex(@media,',4,') > 0
                begin
                    ---------------------------清晰mp4附件---------------------------
                    set @videoPath = 'mp4/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.mp4'
                    insert into Courseware.dbo.tb_Attachment(type,mimeType,path,status,activatedCount,version,updatedDate,createdDate)
                    values (4, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())

                    ---------------------------清晰flv附件---------------------------
                    set @videoPath = 'flv/' + replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.flv'
                    insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                    values (4, 'video/flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())

                    ---------------------------清晰edu4附件---------------------------
                    set @videoPath = replace(@tempPath, cast(@lessonId as varchar(25)) + '/a', cast(@lessonId as varchar(25)) + '/h') + cast(@hvideornd as varchar(25)) + '.edu4'
                    insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                    values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                    insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                    values (@relateId, @@identity, 0, getdate())
                end

            ----------------doc文档----------------
            set @docPath = 'mp3/' + @tempPath + cast(@rnd as varchar(25)) + '.doc'
            insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
            values (10, 'application/vnd.ms-word', @docPath, 1, 0, 1, getdate(), getdate())
            insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
						values (@relateId, @@identity, 0, getdate())
        end
    end
end
