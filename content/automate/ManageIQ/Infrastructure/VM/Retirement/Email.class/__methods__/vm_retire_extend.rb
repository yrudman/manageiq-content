#
# Description: This method is used to add 14 days to retirement date when target
# VM has a retires_on value and is not already retired
#

module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Retirement
          module Email
            class VmRetireExtend
              def initialize(handle = @evm)
                @handle = handle
              end

              def main
                @handle.log("info", "Starting vm_retire_extend")
                vm = @handle.root['vm']
                check_retire_extend(vm)
                @handle.log("info", "Ending vm_retire_extend")
              end

              private

              def check_retire_extend(vm)
                vm_retire_extend_days = @handle.object['vm_retire_extend_days']
                raise "ERROR - vm_retire_extend_days not found!" if vm_retire_extend_days.nil?

                @handle.log("info", "Number of days to extend: <#{vm_retire_extend_days}>")

                vm_name = vm.name

                if vm.retires_on.blank?
                  @handle.log("info", "VM '#{vm_name}' has no retirement date - extension bypassed")
                  exit MIQ_OK
                end

                if vm.retired
                  @handle.log("info", "VM '#{vm_name}' is already retired. retires_on date: #{vm.retires_on}. No Action taken")
                  exit MIQ_OK
                end

                @handle.log("info", "VM: <#{vm_name}> current retirement date is #{vm.retires_on}")
                @handle.log("info", "Extending retirement <#{vm_retire_extend_days}> days for VM: <#{vm_name}>")

                vm.extend_retires_on(vm_retire_extend_days, vm.retires_on)

                @handle.log("info", "VM: <#{vm_name}> new retirement date is #{vm.retires_on}")
                @handle.log("info", "Inspecting retirement vm: <#{vm.retirement_state.try}>")

                evm_owner_id = vm.attributes['evm_owner_id']
                owner = @handle.vmdb('user', evm_owner_id) unless evm_owner_id.nil?
                @handle.log("info", "Inspecting VM Owner: #{owner.inspect}")

                to = if owner
                       owner.email
                     else
                       @handle.object['to_email_address']
                     end

                from = @handle.object['from_email_address']
                signature = @handle.object['signature']
                subject = "VM Retirement Extended for #{vm_name}"

                body = "Hello, "
                body += "<br><br>The retirement date for your virtual machine: [#{vm_name}] has been extended to: [#{vm.retires_on}]."
                body += "<br><br> Thank you,"
                body += "<br> #{signature}"

                @handle.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
                @handle.execute('send_email', to, from, subject, body)
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Infrastructure::VM::Retirement::Email::VmRetireExtend.new.main
end
