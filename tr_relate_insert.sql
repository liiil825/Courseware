BEGIN
	declare @temp table(id int, title nvarchar(100), ishdv bit, lessonId int, classId int, classNum int, relateNum int, lessonyear smallint, media varchar(50), hdvrnd int, audiornd int, svideornd int, hvideornd int, isdemo bit, isfree bit, classId int, isexam bit, test bit, teacherId int, playerver smallint, isword bit, startdate datetime)
	declare @id int, @ishdv bit, @lessonId int, @classId int,@classNum int, @relateNum int, @lessonyear smallint, @media varchar(50), @hdvRnd int, @audioRnd int, @svideornd int, @hvideornd int, @playerver smallint, @isword bit
	declare @relateId int

	insert into @temp
	select relate_id, title ,ishdv ,lesson_id , class_id, classnum, relate, lessonyear, media, hdvrnd, audiornd, svideornd, hvideornd, isdemo, is_free, class_id, isexam, test, teacher_id, playerver, isword, startdate from inserted

	while exists(select id from @temp)
		begin
			select @id = id, @ishdv = ishdv, @lessonId = lessonid, @classId = classId, @classNum = classnum, @relateNum = relatenum, @lessonyear = lessonyear, @media = media, @hdvrnd = hdvrnd, @audiornd = audiornd, @svideornd = svideornd, @hvideornd=hvideornd, @playerver = playerver, @isword=isword from @temp
			
			------------------------------------------------插入讲座信息------------------------------------------------
			insert into Courseware.dbo.tb_Relate(title, description, comment, [type], contentType, [index], [status], updatedDate, createdDate, teacherId, startdate)
			select title, null, null, case when isdemo = 1 and isfree = 1 then 4 when isdemo = 1 and isfree <> 1 then 3 when isfree = 1 and isdemo <> 1 then 2 else 1 end,
			case isexam when 1 then 3
									else (case test when 2 then 2 else 1 end)
			end, relateNum, 0, getdate(), getdate(), teacherid, startdate from @temp
			set @relateId = @@identity

			------------------------------------------------插入讲座与产品关联关系信息------------------------------------------------
			insert into Courseware.dbo.tb_Relate_Product_Mapping(productSource, productType, productId, relateId, type, [year], createdDate)
			select 1, 1, classid, @relateId, 1, lessonyear, getdate() from @temp

			------------------------------------------------插入操作记录------------------------------------------------
            insert into CoursewareWorkflow.dbo.tb_Operation_Record(TargetId, TargetType, CreateDate, [Type], Content, [Comment])
            select 2, @relateId, getdate(), 5, '', ''

			------------------------------------------------插入完成记录后删除------------------------------------------------
			delete from @temp where id = @id

			------------------------------------------------开始插入附件信息------------------------------------------------
			declare @videoPath varchar(256), @audioPath varchar(256), @docPath varchar(256), @htmlPath varchar(256), @tempPath varchar(256), @rnd int

			set @rnd = @audiornd
			if @ishdv = 1
				set @rnd = 0
			if @ishdv = 1 and @hdvrnd > 9999999
				set @rnd = @hdvrnd

			set @tempPath = @lessonId + '/' + (select case @ishdv when 1 then '' else 'a' end) + @lessonId + '-' + @classnum + '-' + @relateNum + '-' + @lessonYear + '-'
			
			---------------------------------------------插入音频附件和HTML文件------------------------------------
			if charIndex(@media, ',1,') > 0
			begin
				set @audioPath = 'mp3/' + @tempPath + @rnd + '.mp3'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (1, 'audio/mp3', @audioPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())

                set @htmlPath = '../../sound/upCourseaware/' + @lessonId + '/' + @lessonyaer + '-' + @classId + '-' @classNum + '-' + @id + '.html'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (12, 'text/html', @htmlPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())
			end

			---------------------------------------------高清视频和讲义---------------------------------------------
			if @ishdv = 1
			begin
                -----------------高清flv附件-----------------
				set @videoPath = 'flv/' + @tempPath + @hdvrnd + '.flv'
				insert into Courseware.dbo.tb_Attachment(type,mimeType,path,status,activatedCount,version,updatedDate,createdDate)
				values (5, 'video/x-flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId,attachmentId,partId,createdDate)
				values (@relateId, @@identity, 0, getdate())
				
                -----------------高清high.m3u8附件-----------------
				set @videoPath = 'hlv/m3u8/' + @tempPath + @hdvrnd + '_high.m3u8'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (6, 'application/x-mpegurl', @videoPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())

                -----------------高清low.m3u8附件-----------------
				set @videoPath = 'hlv/m3u8/' + @tempPath + @hdvrnd + '_low.m3u8'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (7, 'application/x-mpegurl', @videoPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())
				
                -----------------Edu4附件-----------------
                set @videoPath = @lessonId + '/' + @lessonId + '-' + @classNum + '-' + @relateNum + '-' + @lessonYear + @hdvrnd + '.edu4'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (21, 'application/x-edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())

                -----------------pdf文档附件-----------------
				set @docPath = 'mp3/' + @tempPath + @rnd + '.pdf'
				insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
				values (11, 'application/pdf', @docPath, 1, 0, 1, getdate(), getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
				values (@relateId, @@identity, 0, getdate())
			end

			---------------------------------------------普通视频和讲义---------------------------------------------
			else
			begin
                ----------------宽屏----------------
				if charIndex(@media, ',3,') > 0
                    begin
                        ---------------------------宽屏mp4附件---------------------------
                        set @videoPath = 'mp4/' + replace(@tempPath, @lessonId + '/a', @lessonId + '/s') + @svideornd + '.mp4'
                        insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                        values (3, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                        insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                        values (@relateId, @@identity, 0, getdate())

                        ---------------------------宽屏flv附件---------------------------
                        set @videoPath = 'flv/' + replace(@tempPath, @lessonId + '/a', @lessonId + '/s') + @svideornd + '.flv'
                        insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                        values (3, 'video/flv', @videoPath, 1, 0, @playerver, getdate(), getdate())
                        insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                        values (@relateId, @@identity, 0, getdate())

                        ---------------------------宽屏edu4附件---------------------------
                        set @videoPath = replace(@tempPath, @lessonId + '/a', @lessonId + '/s') + @svideornd + '.edu4'
                        insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                        values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                        insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                        values (@relateId, @@identity, 0, getdate())
                    end
                ----------------清晰屏----------------
				if charIndex(@media,',4,') > 0
                    begin
                        ---------------------------清晰mp4附件---------------------------
                        set @videoPath = 'mp4/' + replace(@tempPath, @lessonId + '/a', @lessonId + '/h')+ @hvideornd + '.mp4'
                        insert into Courseware.dbo.tb_Attachment(type,mimeType,path,status,activatedCount,version,updatedDate,createdDate)
                        values (4, 'video/mp4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                        insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                        values (@relateId, @@identity, 0, getdate())

                        ---------------------------清晰edu4附件---------------------------
                        set @videoPath = replace(@tempPath, @lessonId + '/a', @lessonId + '/h') + @hvideornd + '.edu4'
                        insert into Courseware.dbo.tb_Attachment(type, mimeType, path, status, activatedCount, version, updatedDate, createdDate)
                        values (21, 'video/edu4', @videoPath, 1, 0, @playerver, getdate(), getdate())
                        insert into Courseware.dbo.tb_Relation_Mapping(relateId, attachmentId, partId, createdDate)
                        values (@relateId, @@identity, 0, getdate())
                    end

                ----------------doc文档----------------
				set @docPath = 'mp3/' + @tempPath + @rnd + '.doc'
				insert into Courseware.dbo.tb_Attachment(type,mimeType,path,status,activatedCount,version,updatedDate,createdDate)
				values (10,'application/vnd.ms-word',@docPath,1,0,1,getdate(),getdate())
				insert into Courseware.dbo.tb_Relation_Mapping(relateId,attachmentId,partId,createdDate)
				values (@relateId,@@identity,0,getdate())
			end
		end
END

