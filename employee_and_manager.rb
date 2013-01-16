class Employee

  attr_accessor :manager, :name, :title, :salary

  def initialize(name, title, salary)
    @name, @title, @salary = name, title, salary
  end

  def calculate_bonus(multiplier)
    @salary * multiplier
  end

end

class Manager < Employee

  attr_reader :employees, :name, :title, :salary

  def initialize(name, title, salary)
    @employees = []
    super(name, title, salary)
  end

  def assign_employee(employee)
    @employees << employee
    employee.manager = self
  end

  def calculate_bonus(multiplier)

    # cycle through all employees and sub employees adding up their salaries
    base = 0
    queue = [self]
    until queue.size == 0
      current_employee = queue.shift
      base += current_employee.salary
      if current_employee.is_a?(Manager)
        current_employee.employees.each do |employee|
          queue << employee
        end
      end
    end
    base * multiplier
  end

end

jt3 = Manager.new("jt", "programmer", 25000 )
kush = Manager.new("kush", "CEO", 50000)
ned = Manager.new("ned", "lead programmer", 50000)
jt1 = Employee.new("jt", "programmer", 25000 )
jt2 = Employee.new("jt", "programmer", 25000 )


kush.assign_employee(ned)
ned.assign_employee(jt1)
ned.assign_employee(jt2)
kush.assign_employee(jt3)
#puts ned.inspect
#puts kush.inspect
#puts jt1.inspect
puts kush.calculate_bonus(10)