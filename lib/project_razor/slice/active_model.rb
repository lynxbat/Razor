require "json"


# Root ProjectRazor namespace
module ProjectRazor
  module Slice

    # ProjectRazor Slice Active_Model
    class Active_model < ProjectRazor::Slice::Base
      def initialize(args)
        super(args)
        @hidden          = false
        @new_slice_style = true
        @slice_name      = "Active_model"
        @policies        = ProjectRazor::Policies.instance

        # get the slice commands map for this slice (based on the set
        # of commands that are typical for most slices)
        @slice_commands = get_command_map("active_model_help",
                                          "get_all_active_models",
                                          "get_active_model_by_uuid",
                                          nil,
                                          nil,
                                          "remove_all_active_models",
                                          "remove_active_model_by_uuid")
        # and add any additional commands specific to this slice
        @slice_commands[:logview] = "get_logview"
        @slice_commands[:get][/^[\S]+$/][:logs] = "get_active_model_logs"
      end

      def active_model_help
        puts "Active Model Slice: used to view active models or active model logs, and to remove active models.".red
        puts "Active Model Commands:".yellow
        puts "\trazor active_model [get] [all]          " + "View all active models".yellow
        puts "\trazor active_model [get] (UUID) logs    " + "View specific active model (log)".yellow
        puts "\trazor active_model logview              " + "Prints an aggregate active model log view".yellow
        puts "\trazor active_model remove (UUID)|(all)  " + "Remove existing (or all) active model(s)".yellow
        puts "\trazor active_model --help|-h            " + "Display this screen".yellow
      end

      def get_all_active_models
        @command = :get_all_active_models
        # Get all active model instances and print/return
        print_object_array get_object("active_models", :active), "Active Models:", :success_type => :generic, :style => :table
      end

      def get_active_model_by_uuid
        @command = :get_active_model_by_uuid
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        print_object_array [active_model], "", :success_type => :generic
      end

      def get_active_model_logs
        @command = :get_active_model_logs
        # the UUID is the first element of the @command_array
        uuid = @prev_args.peek(1)
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        print_object_array [active_model], "", :success_type => :generic, :style => :table
        print_object_array(active_model.print_log, "", :style => :table)
      end

      def remove_all_active_models
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove all Active Models" unless get_data.delete_all_objects(:active)
        slice_success("All active models removed", :success_type => :removed)
      end

      def remove_active_model_by_uuid
        @command = :get_active_model_logs
        # the UUID is the first element of the @command_array
        uuid = get_uuid_from_prev_args
        active_model = get_object("active_model_instance", :active, uuid)
        raise ProjectRazor::Error::Slice::InvalidUUID, "Cannot Find Active Model with UUID: [#{uuid}]" unless active_model
        raise ProjectRazor::Error::Slice::CouldNotRemove, "Could not remove Active Model [#{active_model.uuid}]" unless get_data.delete_object(active_model)
        slice_success("Active model #{active_model.uuid} removed", :success_type => :removed)
      end

      def get_logview
        active_models = get_object("active_models", :active)
        log_items = []
        active_models.each { |bp| log_items = log_items | bp.print_log_all }
        log_items.sort! { |a, b| a.print_items[3] <=> b.print_items[3] }
        log_items.each { |li| li.print_items[3] = Time.at(li.print_items[3]).strftime("%H:%M:%S") }
        print_object_array(log_items, "All Active Model Logs:", :success_type => :generic, :style => :table)
      end

    end
  end
end


