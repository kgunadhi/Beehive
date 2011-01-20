class JobsController < ApplicationController
  ***REMOVED*** GET /jobs
  ***REMOVED*** GET /jobs.xml
  
  include CASControllerIncludes
  
  skip_before_filter :verify_authenticity_token, :only => [:auto_complete_for_category_name, 
		:auto_complete_for_course_name, :auto_complete_for_proglang_name]
  auto_complete_for :category, :name
  auto_complete_for :course, :name
  auto_complete_for :proglang, :name
  
  ***REMOVED***CalNet / CAS Authentication
  before_filter CASClient::Frameworks::Rails::Filter
  ***REMOVED***before_filter :goto_cas_unless_logged_in
    
  ***REMOVED*** Ensures that only logged-in users can create, edit, or delete jobs
  before_filter :rm_login_required ***REMOVED***, :except => [ :index, :show ]
  
  ***REMOVED*** Ensures that only the user who created a job -- and no other users -- can edit 
  ***REMOVED*** or destroy it.
  before_filter :check_post_permissions, :only => [ :new, :create ]
  before_filter :correct_user_access, :only => [ :edit, :update, :delete, :destroy ]

  protected
  def search_params_hash
    h = {}
    ***REMOVED*** booleans
    [:paid, :credit, :expired, :filled].each do |param|
      h[param] = params[param] if ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[param]) ***REMOVED***unless params[param].nil?
    end
    
    ***REMOVED*** strings, directly copy attribs
    [:query, :tags, :page, :per_page, :as].each do |param|
      h[param] = params[param] unless params[param].blank?
    end

    ***REMOVED*** dept. 0 => all
    h[:department] = params[:department] if params[:department].to_i > 0
    h[:faculty]    = params[:faculty]    if params[:faculty].to_i    > 0

    h
  end

  public
  
  def index ***REMOVED***list
    ***REMOVED*** strip out some weird args
    ***REMOVED*** may cause double-request but that's okay
    redirect_to(search_params_hash) and return if [:commit, :utf8].any? {|k| !params[k].nil?}

    ***REMOVED*** Tags will filter whatever the query returns

    @jobs = Job.find_jobs(params[:query], {
                                :department => params[:department].to_i, 
                                :faculty => params[:faculty].to_i, 
                                :paid => ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:paid]),
                                :credit => ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:credit]),

                                ***REMOVED*** will_paginate
                                :page => params[:page] || 1,
                                :per_page => params[:per_page]
                          })
    
    @department_id = params[:department] ? params[:department].to_i : 0
    @faculty_id    = params[:faculty]    ? params[:faculty].to_i    : 0
    @query         = ((not params[:query].nil?) and (not params[:query].empty?)) ? params[:query] : nil
    
    if params[:tags].present?
      jobs_tagged_with_tags = Job.find_tagged_with(params[:tags])
      @jobs = @jobs.select { |job| jobs_tagged_with_tags.include?(job) }
    end
  	
    respond_to do |format|
            format.html { render :action => :index }
            format.xml { render :xml => @jobs }
    end
  end
    
  ***REMOVED*** GET /jobs/1
  ***REMOVED*** GET /jobs/1.xml
  def show
    @job = Job.find(params[:id])

    ***REMOVED*** update watch time so this job is now 'read'
    if current_user.present? && (watch=Watch.find(:first, :conditions => {:user_id => current_user.id, :job_id => @job.id}))
        watch.mark_read
    end

    respond_to do |format|
      format.html ***REMOVED*** show.html.erb
      format.xml  { render :xml => @job }
    end
  end

  ***REMOVED*** GET /jobs/new
  ***REMOVED*** GET /jobs/new.xml
  def new
    @job = Job.new
	
  end

  ***REMOVED*** GET /jobs/1/edit
  def edit
    @job = Job.find(params[:id])
    @job.mend
    
    respond_to do |format|
        format.html
        format.xml
    end
    
  end

  ***REMOVED*** POST /jobs
  ***REMOVED*** POST /jobs.xml
  def create
    params[:job][:user] = current_user
            
    ***REMOVED*** Handles the text_fields for categories, courses, and programming languages
    params[:job][:category_names] = params[:category][:name] if params[:category]
    params[:job][:course_names] = params[:course][:name] if params[:course]
    params[:job][:proglang_names] = params[:proglang][:name] if params[:proglang]
    
    params[:job][:active] = false
    params[:job][:activation_code] = 0
    

    sponsor = Faculty.find(params[:faculty_sponsor].to_i)
    @job = Job.new(params[:job])

    respond_to do |format|
      if @job.valid_without_sponsorships?
        @sponsorship = Sponsorship.find_or_create_by_faculty_id_and_job_id(sponsor.id, @job.id)
        @job.sponsorships << @sponsorship
        @job.activation_code = ActiveSupport::SecureRandom.random_number(10e6.to_i)
        ***REMOVED*** don't have id at this point     ***REMOVED***(@job.id * 10000000) + (rand(99999) + 100000) ***REMOVED*** Job ID appended to a random 6 digit number.
        @job.save
        flash[:notice] = 'Thank you for submitting a job.  Before this job can be added to our listings page and be viewed by '
        flash[:notice] << 'other users, it must be approved by the faculty sponsor.  An e-mail has been dispatched to the faculty '
        flash[:notice] << 'sponsor with instructions on how to activate this job.  Once activated, users will be able to browse and respond to the job posting.'
        
        ***REMOVED***TODO: Send an e-mail to the faculty member(s) involved.
        ***REMOVED*** At this point, ActionMailer should have been set up by /config/environment.rb
        FacultyMailer.deliver_faculty_confirmer(sponsor.email, sponsor.name, @job)
        
        format.html { redirect_to(@job) }
        format.xml  { render :xml => @job, :status => :created, :location => @job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  ***REMOVED*** PUT /jobs/1
  ***REMOVED*** PUT /jobs/1.xml
  def update	
	  ***REMOVED***params[:job][:sponsorships] = Sponsorship.new(:faculty => Faculty.find(:first, :conditions => [ "name = ?", params[:job][:faculties] ]), :job => nil)	
      
    ***REMOVED*** Handles the text_fields for categories, courses, and programming languages
  	params[:job][:category_names] = params[:category][:name]
  	params[:job][:course_names] = params[:course][:name]
  	params[:job][:proglang_names] = params[:proglang][:name] 
    
    @job = Job.find(params[:id])
    @faculty_names = Faculty.all.map {|f| f.name }
	
	  update_sponsorships  	
			
    respond_to do |format|
      if @job.update_attributes(params[:job])
        
        populate_tag_list
        @job.save
        flash[:notice] = 'Job was successfully updated.'
        format.html { redirect_to(@job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end
  

  ***REMOVED*** Just the page that asks for confirmation for deletion of the job.
  ***REMOVED*** The actual deletion is performed by the "destroy" action.
  def delete
    @job = Job.find(params[:id])
    
    respond_to do |format|
      format.html
      format.xml
    end
  end

  ***REMOVED*** DELETE /jobs/1
  ***REMOVED*** DELETE /jobs/1.xml
  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      flash[:notice] = "Listing deleted successfully."
      format.html { redirect_to(jobs_url) }
      format.xml  { head :ok }
    end
  end
  
  def activate
    ***REMOVED*** /jobs/activate/job_id?a=xxx
	  @job = Job.find(:first, :conditions => [ "activation_code = ? AND active = ?", params[:a], false ])
	
	  if @job != nil
  		populate_tag_list
		
  		@job.skip_handlers = true
  		@job.active = true
  		saved = @job.save
  	else 
  		saved = false
  	end
	
  	respond_to do |format|
  		if saved
  		  @job.skip_handlers = false
  		  flash[:notice] = 'Job activated successfully.  Your job is now available to be browsed and viewed by other users.'
  		  format.html { redirect_to(@job) }
  		else
  		  flash[:notice] = 'Unsuccessful activation.  Either this job has already been activated or the activation code is incorrect.'
  		  format.html { redirect_to(jobs_url) }
  		end
  	end
  end
  
  def job_read_more
	  job = Job.find(params[:id])
  	render :text=> job.desc
  end
  
  def job_read_less
	  job = Job.find(params[:id])
  	desc = job.desc.first(100)
  	desc = desc << "..." if job.desc.length > 100
  	render :text=>  desc
  end
  
  def watch	
	  job = Job.find(params[:id])
  	watch = Watch.new({:user=> current_user, :job => job})
	
  	respond_to do |format|
  		if watch.save
  		  flash[:notice] = 'Job is now watched. You can find a list of your watched jobs on the dashboard.'
  		  format.html { redirect_to(:controller=>:dashboard) }
  		else
  		  flash[:notice] = 'Unsuccessful job watch. Perhaps you\'re already watching this job?'
  		  format.html { redirect_to(:controller=>:dashboard) }
  		end
  	end
  end
  
 def unwatch	
   job = Job.find(params[:id])
   watch = Watch.find(:first, :conditions=>{:user_id=> current_user.id, :job_id => job.id})

   respond_to do |format|
  	 if watch.destroy
  	   flash[:notice] = 'Job is now unwatched. You can find a list of your watched jobs on the dashboard.'
  	   format.html { redirect_to(:controller=>:dashboard) }
  	 else
  	   flash[:notice] = 'Unsuccessful job un-watch. Perhaps you\'re not watching this job yet?'
  	   format.html { redirect_to(:controller=>:dashboard) }
  	 end
   end
	
  end
  
  
***REMOVED******REMOVED***  ***REMOVED*** the action for actually applying.
***REMOVED******REMOVED***  def apply
***REMOVED******REMOVED***    job = Job.find(params[:id])
***REMOVED******REMOVED***    
***REMOVED******REMOVED***    if job.nil? or params[:applic].nil?
***REMOVED******REMOVED***        flash[:error] = "Error: Couldn't tell which job you want to apply to. Please try again from the listing page."
***REMOVED******REMOVED***        redirect_to(:controller=>:jobs, :action=>:index)
***REMOVED******REMOVED***        return
***REMOVED******REMOVED***    end
***REMOVED******REMOVED***    
***REMOVED******REMOVED***    applic = Applic.new({:user_id => current_user.id, :job_id => job.id}.update(params[:applic]))
***REMOVED******REMOVED***    applic.resume_id = current_user.resume.nil? ? nil : current_user.resume.id
***REMOVED******REMOVED***    applic.transcript_id = current_user.transcript.nil? ? nil : current_user.transcript.id
***REMOVED******REMOVED***    
***REMOVED******REMOVED***    respond_to do |format|
***REMOVED******REMOVED***        if applic.save
***REMOVED******REMOVED***            flash[:notice] = 'Applied for job successfully. Time to cross your fingers and wait for a reply!'
***REMOVED******REMOVED***            format.html { redirect_to(:controller=>:dashboard) }
***REMOVED******REMOVED***        else
***REMOVED******REMOVED***            flash[:error] = "Could not apply to position. Make sure you've written " + 
***REMOVED******REMOVED***                            "a message to the faculty sponsor!"
***REMOVED******REMOVED***            format.html { redirect_to(:controller=>:jobs, :action => :goapply, :id => params[:id]) }
***REMOVED******REMOVED***        end
***REMOVED******REMOVED***    end
***REMOVED******REMOVED***  end
***REMOVED******REMOVED***  
***REMOVED******REMOVED***  ***REMOVED*** withdraw from an application (destroy the applic)
***REMOVED******REMOVED***  def withdraw
***REMOVED******REMOVED***    applic = Applic.find(:job_id=>params[:id])
***REMOVED******REMOVED***    if !applic.nil? && applic.user == current_user
***REMOVED******REMOVED***        respond_to do |format|
***REMOVED******REMOVED***            if applic.destroy
***REMOVED******REMOVED***                flash[:error] = "Withdrew your application successfully. Keep in mind that your initial application email has already been sent."
***REMOVED******REMOVED***                format.html { redirect_to(:controller=>:jobs, :action=>:index) }
***REMOVED******REMOVED***            else
***REMOVED******REMOVED***                flash[:error] = "Couldn't withdraw your application. Try again, or contact support."
***REMOVED******REMOVED***                format.html { redirect_to(:controller=>:dashboard) }
***REMOVED******REMOVED***            end
***REMOVED******REMOVED***        end
***REMOVED******REMOVED***    else
***REMOVED******REMOVED***        flash[:error] = "Error: Couldn't find that application."
***REMOVED******REMOVED***        redirect_to(:controller=>:dashboard)
***REMOVED******REMOVED***    end
***REMOVED******REMOVED***  end
  
  protected
    ***REMOVED*** Saves sponsorship specified in the params page
    def update_sponsorships
        fac = Faculty.exists?(params[:faculty_name]) ? params[:faculty_name] : 0
        sponsor = Sponsorship.find(:first, :conditions => {:job_id=>@job.id, :faculty_id=>fac} ) || Sponsorship.create(:job_id=>@job.id, :faculty_id=>fac)
        @job.sponsorships = [sponsor]
    end
  
  
	  ***REMOVED*** Populates the tag_list of the job.
	def populate_tag_list
		tags_string = ""
        tags_string << @job.department.name
		tags_string << ',' + @job.category_list_of_job 
		tags_string << ',' + @job.course_list_of_job unless @job.course_list_of_job.empty?
		tags_string << ',' + @job.proglang_list_of_job unless @job.proglang_list_of_job.empty?
		tags_string << ',' + (@job.paid ? 'paid' : 'unpaid')
		tags_string << ',' + (@job.credit ? 'credit' : 'no credit')
		@job.tag_list = tags_string
	end
  
  private
  

	
	def correct_user_access
		if (Job.find(params[:id]) == nil || current_user != Job.find(params[:id]).user)
			flash[:error] = "Unauthorized access denied. Do not pass Go. Do not collect $200."
			redirect_to :controller => 'dashboard', :action => :index
		end
	end
	
	def check_post_permissions
	    if not current_user.can_post?
	        flash[:error] = "Sorry, you don't have permissions to post a new listing. Become a grad student or ask to be hired as faculty."
	        redirect_to :controller => 'dashboard', :action => :index
	    end
	end
	
end
