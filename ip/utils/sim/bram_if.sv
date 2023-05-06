

package bramif_pkg;

interface class BramIf #(type data_t = logic, type addr_t = logic);
pure virtual task write(input addr_t addr, input data_t data);
pure virtual task read(input addr_t addr, output data_t data);
endclass

endpackage